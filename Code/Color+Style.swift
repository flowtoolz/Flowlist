import SwiftyToolz

extension Color
{
    static let backlog = Color.white.with(alpha: 0.5)
    static let background = Color.white.with(alpha: 0.5)
    static let done = Color.black.with(alpha: 0.05)
    
    static let border = Color.white.with(alpha: 0.25)
    static let grayedOut = Color.black.with(alpha: 0.5)
    
    static let flowlistBlueTransparent = flowlistBlue.with(alpha: 0.5)
    static let flowlistBlueVeryTransparent = flowlistBlue.with(alpha: 0.25)
    static let flowlistBlue = Color(36, 145, 241)
    static let discountRed = Color(0.75, 0, 0, 0.75)
}

fileprivate let darkeningFactor: Float = 0.92
