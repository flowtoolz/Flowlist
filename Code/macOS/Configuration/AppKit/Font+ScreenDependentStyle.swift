import AppKit
import SwiftObserver
import SwiftyToolz

extension Font
{
    static var text: Font
    {
        .system(size: baseSize.value, weight: .system)
    }
    
    static var listTitle: Font
    {
        .system(size: Int(1.6 * Float(baseSize.value)),
                weight: .semibold)
    }
    
    static let baseSize = Var(defaultSize)
    
    static let defaultSize: Int =
    {
        guard let screenSize = NSScreen.main?.frame.size else { return 14 }

        return Int(screenSize.width * 0.011)
    }()
}
