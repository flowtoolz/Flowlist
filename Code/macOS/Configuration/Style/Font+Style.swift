import SwiftObserver
import SwiftyToolz

extension Font
{
    static var text: Font
    {
        return Font.system(size: baseSize.latestMessage, weight: .system)
    }
    
    static var listTitle: Font
    {
        return Font.system(size: Int(1.6 * Float(baseSize.latestMessage)),
                           weight: .semibold)
    }
    
    static var title: Font
    {
        return Font.system(size: 28, weight: .semibold)
    }
    
    static var purchasePanel: Font
    {
        return Font.system(size: 14, weight: .system)
    }
    
    static let baseSize = Var(defaultSize).new()

    static let defaultSize: Int =
    {
        guard let screenSize = NSScreen.main?.frame.size else { return 14 }

        return Int(screenSize.width * 0.011)
    }()
}