import SwiftyToolz

extension Double
{
    static let groupIconWidthFactor: Double = 0.75
    static let relativeTextInset: Double = 0.85
    static let listCornerRadius: Double = 6
    static let listGap: Double = 10
    static let cornerRadius: Double = 3
    static let progressBarHeight: Double = 10
    
    static func itemPadding(for lineHeight: Double) -> Double
    {
        0.5 * lineHeight + lineSpacing(for: lineHeight)
    }
    
    static func lineSpacing(for lineHeight: Double) -> Double
    {
        Double(Int(relativeSpacing * lineHeight + 0.5))
    }
    
    private static let relativeSpacing: Double = 5.0 / 17.0 // 5 @ line height 17
}
