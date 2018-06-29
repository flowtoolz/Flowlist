import SwiftyToolz

extension Color
{
    static let backlog = Color.white
    static let background = Color.gray(brightness: darkeningFactor)
    static let done = Color.gray(brightness: powf(darkeningFactor, 2))
    
    static let border = Color(0, 0, 0, 0.15)
    static let grayedOut = Color(0, 0, 0, 0.33)
    static let flowlistBlue = Color(36, 145, 241)
    static let discountRed = Color(0.75, 0, 0, 0.75)
}

fileprivate let darkeningFactor: Float = 0.92
