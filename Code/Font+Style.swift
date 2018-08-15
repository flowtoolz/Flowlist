import SwiftyToolz

extension Font
{
    static let text = Font.system(size: baseFontSize, weight: .system)
    static let listTitle = Font.system(size: baseFontSize, weight: .semibold)
    static let title = Font.system(size: 2 * baseFontSize, weight: .bold)
    
    static let baseFontSize = 14
}
