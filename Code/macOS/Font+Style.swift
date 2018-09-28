import AppKit
import SwiftObserver
import SwiftyToolz

extension Font
{
    static var text: Font
    {
        return Font.system(size: baseSize.latestUpdate, weight: .system)
    }
    
    static var listTitle: Font
    {
        return Font.system(size: Int(1.6 * Float(baseSize.latestUpdate)),
                           weight: .light)
    }
    
    static var title: Font
    {
        return Font.system(size: 28, weight: .light)
    }
    
    static var purchasePanel: Font
    {
        return Font.system(size: 14, weight: .system)
    }
    
    static let baseSize = baseSizeVar.new().filter({ $0 != nil }).unwrap(defaultSize)
    static let baseSizeVar = Var(defaultSize)
    static let defaultSize: Int =
    {
        guard let screenSize = NSScreen.main?.frame.size else { return 14 }

        return Int(screenSize.width * 0.011)
    }()
}
