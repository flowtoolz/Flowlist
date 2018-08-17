import SwiftObserver
import SwiftyToolz

extension Font
{
    static var text: Font
    {
        return Font.system(size: baseSize.latestUpdate,
                           weight: .system)
    }
    
    static var listTitle: Font
    {
        return Font.system(size: baseSize.latestUpdate,
                           weight: .semibold)
    }
    
    static var title: Font
    {
        return Font.system(size: 2 * baseSize.latestUpdate,
                           weight: .bold)
    }
    
    static let baseSize = baseSizeVar.new().filter({ $0 != nil }).unwrap(defaultSize)
    static let baseSizeVar = Var(defaultSize)
    private static let defaultSize = 14
}
