import Foundation
import StoreKit
import SwiftyToolz
import SwiftObserver

let inAppPurchaseController = InAppPurchaseController()

class InAppPurchaseController: NSObject, Observable, SKProductsRequestDelegate, SKPaymentTransactionObserver
{
    fileprivate override init() { super.init() }
    
    // MARK: Observe Transactions
    
    func setup() { SKPaymentQueue.default().add(self) }
    
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
    
    // MARK: - Buy or Restore Full Version
    
    func requestPaymentForFullVersion()
    {
        guard userCanPay, let product = fullVersionProduct else { return }
        
        let payment = SKPayment(product: product)
        
        SKPaymentQueue.default().add(payment)
    }
    
    private func didUpdateFullVersionPurchaseTransaction(_ transaction: SKPaymentTransaction)
    {
        guard transaction.payment.productIdentifier == fullVersionId else { return }

        switch transaction.transactionState
        {
        case .purchasing: break
        case .purchased:
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
            send(.didPurchaseFullVersion)
            SKPaymentQueue.default().finishTransaction(transaction)
        case .deferred: break
        }
    }
    
    private func unlockFullVersion()
    {
        print("TODO: UNLOCK FULL VERSION")
        // update limitation flag
        // persist limitation flag
    }
    
    var userCanPay: Bool { return SKPaymentQueue.canMakePayments() }
    
    // MARK: - Load Full Version Product From AppStore
    
    func retrieveFullVersionProduct()
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
                return
            }
        }
    }
    
    var fullVersionProduct: SKProduct?
    private let fullVersionId = "com.flowtoolz.flowlist.full_version"
    
    // MARK: - Load Product IDs From File
    
    func printProductIdentifiers()
    {
        let identifiers = loadProductIdentifiers()
        
        for id in identifiers
        {
            print(id)
        }
    }
    
    private func loadProductIdentifiers() -> [String]
    {
        guard let fileUrl = productIdentifiersFileUrl,
            let data = try? Data(contentsOf: fileUrl)
            else
        {
            return []
        }
        
        let plist = try? PropertyListSerialization.propertyList(from: data,
                                                                options: [],
                                                                format: nil)
        
        return (plist as? [String]) ?? []
    }
    
    private var productIdentifiersFileUrl: URL?
    {
        return Bundle.main.url(forResource: "product_identifiers",
                               withExtension: "plist")
    }
    
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
