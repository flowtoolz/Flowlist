import SwiftyToolz

extension Float
{
    static let verticalGap: Float = 2
}

extension Color
{
    static let done = Color(225, 225, 225, 255)
    static let selected = Color(163, 205, 254, 255)
    static let border = Color(0, 0, 0, 0.15)
    static let grayedOut = Color(0, 0, 0, 0.33)
}

extension Font
{
    static let text = Font.system(size: 13)
}

extension NSView
{
    func applyItemStyle()
    {
        wantsLayer = true
        layer?.borderColor = Color.border.nsColor.cgColor
        layer?.borderWidth = 1.0
        layer?.cornerRadius = 4.0
    }
}
