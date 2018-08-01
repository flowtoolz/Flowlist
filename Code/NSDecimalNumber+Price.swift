import Foundation

public extension NSDecimalNumber
{
    public func formattedPrice(in locale: Locale = Locale.current) -> String?
    {
        let formatter = NumberFormatter()
        
        formatter.locale = locale
        formatter.formatterBehavior = .behavior10_4
        formatter.numberStyle = .currency
        
        return formatter.string(from: self)
    }
}
