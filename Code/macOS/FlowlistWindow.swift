import AppKit
import SwiftyToolz

let mainWindow = FlowlistWindow()

class FlowlistWindow: Window
{
    // MARK: - Initialization
    
    fileprivate init()
    {
        super.init(with: ViewController())
        
        backgroundColor = Color.background.nsColor
    }
    
    // MARK: - Sizing
    
    func didEndResizing()
    {
        guard Window.intendedMainWindowSize != frame.size else { return }
        
        Window.intendedMainWindowSize = frame.size
        
        (contentViewController as? ViewController)?.didEndResizing()
    }
}
