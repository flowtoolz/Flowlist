import SwiftyToolz

extension Float
{
    static let tagAlpha: Float = 0.4
    static let cornerRadius: Float = 6
    static let progressBarHeight: Float = 10
    
    static func lineSpacing(for lineHeight: Float) -> Float
    {
        return 2 * itemPadding(for: lineHeight) - lineHeight
    }
    
    static func itemPadding(for lineHeight: Float) -> Float
    {
        return Float(Int(lineHeight * 0.647 + 0.5))
    }
}
