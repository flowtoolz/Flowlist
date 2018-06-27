import StoreKit

extension SKProduct
{
    var formattedPrice: String?
    {
        return price.formattedPrice(in: priceLocale)
    }
}
