import SwiftyToolz

extension Float
{
    static let cornerRadius: Float = 3
    static let progressBarHeight: Float = 10
    
    static func itemPadding(for lineHeight: Float) -> Float
    {
        return 0.5 * lineHeight + lineSpacing(for: lineHeight)
    }
    
    static func lineSpacing(for lineHeight: Float) -> Float
    {
        return Float(Int(relativeSpacing * lineHeight + 0.5))
    }
    
    private static let relativeSpacing: Float = 5.0 / 17.0 // 5 @ line height 17
}
