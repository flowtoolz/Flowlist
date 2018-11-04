import StoreKit
import Foundation
import FoundationToolz
import SwiftObserver
import SwiftyToolz

let purchaseController = PurchaseController()

class PurchaseController: NSObject, Observable, SKProductsRequestDelegate, SKPaymentTransactionObserver
{
    // MARK: - Life Cycle
    
    fileprivate override init() { super.init() }
    
    func setup() { SKPaymentQueue.default().add(self) }
    
    deinit { removeObservers() }
    
    // MARK: - Restore Purchases
    
    func restorePurchases()
    {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    func paymentQueue(_ queue: SKPaymentQueue,
                      restoreCompletedTransactionsFailedWithError error: Error)
    {
        send(.didFailToPurchaseFullVersion(message: "An error occured while restoring AppStore purchases."))
        
        log(error: error.localizedDescription)
    }
    
    // MARK: - Purchase Full Version
    
    func purchaseFullVersion()
    {
        guard userCanPay else
        {
            send(.didFailToPurchaseFullVersion(message: "Cannot purchase full version because the user is not eligible to pay in the AppStore."))
            return
        }
        
        guard let product = fullVersionProduct else
        {
            send(.didFailToPurchaseFullVersion(message: "Cannot purchase full version because product infos haven't yet been downloaded."))
            return
        }
        
        let payment = SKPayment(product: product)
        
        SKPaymentQueue.default().add(payment)
    }
    
    private var userCanPay: Bool { return SKPaymentQueue.canMakePayments() }
    
    // MARK: - Observe Payment Queue
    
    func paymentQueue(_ queue: SKPaymentQueue,
                      updatedTransactions transactions: [SKPaymentTransaction])
    {
        for transaction in transactions
        {
            if transaction.payment.productIdentifier == fullVersionId
            {
                DispatchQueue.main.async
                {
                    self.didUpdateFullVersionPurchaseTransaction(transaction)
                }
            }
        }
    }
    
    private func didUpdateFullVersionPurchaseTransaction(_ transaction: SKPaymentTransaction)
    {
        guard transaction.payment.productIdentifier == fullVersionId else { return }

        switch transaction.transactionState
        {
        case .purchasing: break
            
        case .purchased, .restored:
            isFullVersion = true
            send(.didPurchaseFullVersion)
            SKPaymentQueue.default().finishTransaction(transaction)
            
        case .failed:
            guard let error = transaction.error else
            {
                let message = "Purchasing full version failed with technical error."
                log(error: message)
                send(.didFailToPurchaseFullVersion(message: message))
                return
            }
            
            let message = "Purchasing full version failed with error: \(error.localizedDescription)"
            log(error: message)
            send(.didFailToPurchaseFullVersion(message: message))
            SKPaymentQueue.default().finishTransaction(transaction)
            
        case .deferred: break
        }
    }
    
    // MARK: - Load Full Version Product From AppStore
    
    func loadFullVersionProductFromAppStore()
    {
        productLoadingTimer?.invalidate()
        
        productLoadingTimer = Timer.scheduledTimer(timeInterval: 10.0,
                                                   target: self,
                                                   selector: #selector(productLoadingDidTimeOut),
                                                   userInfo: nil,
                                                   repeats: false)
        
        fullVersionProduct = nil
        
        productsRequest = SKProductsRequest(productIdentifiers: [fullVersionId])
        productsRequest?.delegate = self
        
        productsRequest?.start()
    }
    
    @objc private func productLoadingDidTimeOut()
    {
        productLoadingTimer?.invalidate()
        
        send(.didCancelLoadingFullversionProductBecauseOffline)
    }
    
    private var productsRequest: SKProductsRequest?
    
    public func productsRequest(_ request: SKProductsRequest,
                                didReceive response: SKProductsResponse)
    {
        productLoadingTimer?.invalidate()
        
        for product in response.products
        {
            if product.productIdentifier == fullVersionId
            {
                fullVersionProduct = product
            }
        }
        
        DispatchQueue.main.async { self.didProcessProductsResponse() }
    }
    
    private var productLoadingTimer: Timer?
    
    private func didProcessProductsResponse()
    {
        if fullVersionProduct != nil
        {
            send(.didLoadFullVersionProduct)
        }
        else
        {
            send(.didFailToLoadFullVersionProduct)
        }
    }
    
    var fullVersionProduct: SKProduct?
    {
        didSet
        {
            fullVersionPrice = fullVersionProduct?.price
            fullVersionPriceLocale = fullVersionProduct?.priceLocale
            fullVersionFormattedPrice = fullVersionProduct?.formattedPrice
        }
    }
    
    
    private let fullVersionId = "com.flowtoolz.flowlist.fullversion"
    
    // MARK: - Discount
    
    var summerDiscountIsAvailable: Bool
    {
        guard let discountEnd = summerDiscountEnd else { return false }
        
        return Date() < discountEnd
    }
    
    private let summerDiscountEnd: Date? =
    {
        var dateComponents = DateComponents()
        dateComponents.day = 20
        dateComponents.month = 9
        dateComponents.year = 2018
        
        return Calendar.current.date(from: dateComponents)
    }()
    
    // MARK: - Observability
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event: Equatable
    {
        case didNothing
        case didLoadFullVersionProduct
        case didFailToLoadFullVersionProduct
        case didCancelLoadingFullversionProductBecauseOffline
        case didPurchaseFullVersion
        case didFailToPurchaseFullVersion(message: String)
    }
}
