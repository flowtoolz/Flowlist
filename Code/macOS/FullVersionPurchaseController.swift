import Foundation
import StoreKit
import SwiftyToolz
import SwiftObserver

let fullVersionPurchaseController = FullVersionPurchaseController()

class FullVersionPurchaseController: NSObject, Observable, SKProductsRequestDelegate, SKPaymentTransactionObserver
{
    // MARK: - Life Cycle
    
    fileprivate override init() { super.init() }
    
    func setup() { SKPaymentQueue.default().add(self) }
    
    deinit { removeObservers() }
    
    // MARK: - Buy or Restore Full Version
    
    func purchaseFullVersion()
    {
        guard userCanPay else
        {
            send(.didFailToPurchaseFullVersion(message: "Cannot purchase full version because user is not eligible to pay in the AppStore."))
            return
        }
        
        guard let product = fullVersionProduct else
        {
            send(.didFailToPurchaseFullVersion(message: "Cannot purchase full version because product infos haven't yet been downloaded from the AppStore."))
            return
        }
        
        let payment = SKPayment(product: product)
        
        SKPaymentQueue.default().add(payment)
    }
    
    func paymentQueue(_ queue: SKPaymentQueue,
                      updatedTransactions transactions: [SKPaymentTransaction])
    {
        for transaction in transactions
        {
            if transaction.payment.productIdentifier == fullVersionId
            {
                didUpdateFullVersionPurchaseTransaction(transaction)
            }
        }
    }
    
    private func didUpdateFullVersionPurchaseTransaction(_ transaction: SKPaymentTransaction)
    {
        guard transaction.payment.productIdentifier == fullVersionId else { return }

        switch transaction.transactionState
        {
        case .purchasing: break
        case .purchased:
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
        case .restored:
            isFullVersion = true
            send(.didPurchaseFullVersion)
            SKPaymentQueue.default().finishTransaction(transaction)
        case .deferred: break
        }
    }
    
    private var userCanPay: Bool { return SKPaymentQueue.canMakePayments() }
    
    // MARK: - Load Full Version Product From AppStore
    
    func loadFullVersionProductFromAppStore()
    {
        fullVersionProduct = nil
        
        productsRequest = SKProductsRequest(productIdentifiers: [fullVersionId])
        productsRequest?.delegate = self
        
        productsRequest?.start()
    }
    
    private var productsRequest: SKProductsRequest?
    
    public func productsRequest(_ request: SKProductsRequest,
                                didReceive response: SKProductsResponse)
    {
        for product in response.products
        {
            if product.productIdentifier == fullVersionId
            {
                fullVersionProduct = product
            }
        }
        
        DispatchQueue.main.async { self.didProcessProductsResponse() }
    }
    
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
    private let fullVersionId = "com.flowtoolz.flowlist.full_version"
    
    // MARK: Observability
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event: Equatable
    {
        case didNothing
        case didLoadFullVersionProduct
        case didFailToLoadFullVersionProduct
        case didPurchaseFullVersion
        case didFailToPurchaseFullVersion(message: String)
    }
}
