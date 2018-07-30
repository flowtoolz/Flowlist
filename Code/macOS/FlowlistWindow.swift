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
    
    // MARK: - Style the Field Editor
    
    override func fieldEditor(_ createFlag: Bool, for object: Any?) -> NSText?
    {
        let text = super.fieldEditor(createFlag, for: object)
        
        text?.backgroundColor = .clear

        let selectionColor = Color.flowlistBlue.nsColor
        let textView = text as? NSTextView
        textView?.selectedTextAttributes = [.backgroundColor: selectionColor,
                                            .foregroundColor: NSColor.white]
        
        return text
    }
}
