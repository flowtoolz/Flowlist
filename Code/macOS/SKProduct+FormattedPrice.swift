import StoreKit

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
    
    var formattedDiscountPrice: String?
    {
        guard #available(OSX 10.13.2, *), let discount = introductoryPrice else
        {
            return nil
        }
        
        let formatter = NumberFormatter()
        
        formatter.locale = discount.priceLocale
        formatter.formatterBehavior = .behavior10_4
        formatter.numberStyle = .currency
        
        return formatter.string(from: discount.price)
    }
}
