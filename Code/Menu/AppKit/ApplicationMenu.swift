import AppKit
import UIToolz
import SwiftObserver
import SwiftyToolz

// TODO: use use generic class for this from Cocoalytics

class ApplicationMenu: NSMenu
{
    // MARK: - Initialization
    
    init()
    {
        super.init(title: "Application Menu")
 
        addItem(withTitle: "Hide Flowlist",
                action: #selector(NSApplication.hide(_:)),
                keyEquivalent: "h")
        addItem(withTitle: "Quit Flowlist",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q")
    }
    
    required init(coder decoder: NSCoder) { fatalError() }
}
