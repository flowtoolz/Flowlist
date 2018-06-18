import Foundation
import StoreKit

class InAppPurchaseController: NSObject, SKProductsRequestDelegate
{
    // MARK: - Load Product From AppStore
    
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
                
                return
            }
        }
    }
    
    private var fullVersionProduct: SKProduct?
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
}
