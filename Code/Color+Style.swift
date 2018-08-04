import SwiftyToolz

extension Color
{
    static let backlog = Color.white
    static let background = Color.gray(brightness: 0.92)
    static let done = Color.gray(brightness: 0.92 * 0.92)
    
    static let border = Color.black.with(alpha: 0.15)
    static let grayedOut = Color.black.with(alpha: 0.5)
    
    static let flowlistBlue = Color(36, 145, 241)

    static let discountRed = Color(0.75, 0, 0, 0.75)
}
