import SwiftyToolz

extension Color
{
    static let backlog = Color.white
    static let background = Color.gray(brightness: 0.92)
    static let done = Color.gray(brightness: 0.92 * 0.92)
    static let windowBackground = Color.gray(brightness: 0.92 * 0.92)
    static let selection = Color.black
    static let border = Color.black.with(alpha: 0.15)
    static let grayedOut = Color.black.with(alpha: 0.5)
    static let discountRed = Color(0.75, 0, 0, 0.75)
    
    static let tags: [Color] =
    [
        Color(253, 74, 75),
        Color(253, 154, 57),
        Color(254, 207, 60),
        Color(95, 197, 64),
        Color(63, 169, 242),
        Color(197, 112, 219)
    ]
}
