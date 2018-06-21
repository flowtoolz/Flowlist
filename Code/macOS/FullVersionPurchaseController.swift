import Foundation
import StoreKit
import SwiftyToolz
import SwiftObserver

let fullVersionPurchaseController = FullVersionPurchaseController()

class FullVersionPurchaseController: NSObject, Observable, SKProductsRequestDelegate, SKPaymentTransactionObserver
{
    // MARK: - Setup
    
    fileprivate override init() { super.init() }
    
    func setup() { SKPaymentQueue.default().add(self) }
    
    // MARK: - Buy or Restore Full Version
    
    func purchaseFullVersion()
    {
        guard userCanPay, let product = fullVersionProduct else { return }
        
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
                send(.didLoadFullVersionProduct)
            }
        }
    }
    
    var fullVersionProduct: SKProduct?
    private let fullVersionId = "com.flowtoolz.flowlist.full_version"
    
    // MARK: Observability
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event
    {
        case didNothing
        case didLoadFullVersionProduct
        case didPurchaseFullVersion
        case didFailToPurchaseFullVersion(message: String)
    }
}

extension SKProduct
{
    var formattedPrice: String?
    {
        let formatter = NumberFormatter()
        
        formatter.locale = priceLocale
        formatter.formatterBehavior = .behavior10_4
        formatter.numberStyle = .currency
        
        return formatter.string(from: price)
    }
}