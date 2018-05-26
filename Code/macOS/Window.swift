import AppKit

class Window: NSWindow
{
    // MARK: - Initialization
    
    convenience init(delegate: NSWindowDelegate)
    {
        self.init()
        self.delegate = delegate
    }
    
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
        
        title = "Flowlist"
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
}
