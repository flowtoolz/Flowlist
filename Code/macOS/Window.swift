import AppKit
import SwiftyToolz

let mainWindow = Window()

class Window: NSWindow
{
    // MARK: - Initialization
    
    override init(contentRect: NSRect,
                  styleMask style: StyleMask,
                  backing backingStoreType: BackingStoreType,
                  defer flag: Bool)
    {
        let windowStyle: StyleMask = [.resizable,
                                      .titled,
                                      .miniaturizable,
                                      .closable]
        
        super.init(contentRect: contentRect,
                   styleMask: windowStyle,
                   backing: backingStoreType,
                   defer: flag)
        
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        backgroundColor = Color.background.nsColor
        
        collectionBehavior = [.managed, .fullScreenPrimary] // required for macOS 10.10
        
        isReleasedWhenClosed = false
        contentViewController = ViewController()
        initializeFrame()
    }
    
    private func initializeFrame()
    {
        let screenFrame = NSScreen.main?.frame ?? CGRect(x: 0,
                                                         y: 0,
                                                         width: 1280,
                                                         height: 800)
        setFrame(CGRect(x: screenFrame.size.width * 0.1,
                        y: screenFrame.size.height  * 0.1,
                        width: screenFrame.size.width * 0.8,
                        height: screenFrame.size.height * 0.8),
                 display: false)
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
    
    // MARK: - Show & Hide
    
    func toggle() { show(!isVisible) }
    
    func show(_ show: Bool = true)
    {
        if show
        {
            makeKeyAndOrderFront(self)
        }
        else
        {
            orderOut(self)
        }
    }
    
    // MARK: - Avoid Beep from Unprocessed Keys
    
    override func noResponder(for eventSelector: Selector) {}
}
