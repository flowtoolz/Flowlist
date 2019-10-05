import StoreKit

extension SKProduct
{
    var formattedPrice: String?
    {
        price.formattedPrice(in: priceLocale)
    }
}
