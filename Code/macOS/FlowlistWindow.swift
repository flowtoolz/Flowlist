import AppKit
import SwiftyToolz

let mainWindow = FlowlistWindow()

class FlowlistWindow: Window
{
    // MARK: - Initialization
    
    fileprivate init()
    {
        Table.windowWidth = Window.initialFrame.size.width
        
        super.init(with: ViewController())
        
        backgroundColor = Color.background.nsColor
    }
    
    // MARK: - Sizing
    
    func didEndResizing()
    {
        Table.windowWidth = frame.size.width
        
        (contentViewController as? ViewController)?.didEndResizing()
    }
}
