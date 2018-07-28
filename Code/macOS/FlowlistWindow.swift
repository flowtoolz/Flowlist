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
