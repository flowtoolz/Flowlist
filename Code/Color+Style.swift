import SwiftyToolz

extension Color
{
    static let backlog = Color.white
    static let background = Color.gray(brightness: 0.92)
    static let done = Color.gray(brightness: 0.92 * 0.92)
    static let windowBackground = Color.gray(brightness: 0.92 * 0.92)
    static let selection = Color.gray(brightness: 0.4)
    static let border = Color.black.with(alpha: 0.15)
    static let grayedOut = Color.black.with(alpha: 0.5)
    static let discountRed = Color(0.75, 0, 0, 0.75)
}
