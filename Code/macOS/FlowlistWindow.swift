import AppKit
import UIToolz
import SwiftyToolz

let mainWindow = FlowlistWindow()

class FlowlistWindow: Window
{
    // MARK: - Initialization
    
    fileprivate init()
    {
        super.init(with: ViewController())
        
        backgroundColor = Color.window.nsColor
    }
}
