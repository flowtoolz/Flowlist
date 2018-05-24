import AppKit

class Window: NSWindow
{
    override init(contentRect: NSRect,
                  styleMask style: NSWindow.StyleMask,
                  backing backingStoreType: NSWindow.BackingStoreType,
                  defer flag: Bool)
    {
        super.init(contentRect: contentRect,
                   styleMask: style,
                   backing: backingStoreType,
                   defer: flag)
        
        isReleasedWhenClosed = false
        styleMask = [.resizable,
                     .titled,
                     .miniaturizable,
                     .closable,
                     .unifiedTitleAndToolbar]
        
        title = "Flowlist"
    }
    
    func setupFrame()
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
    
    func toggle() { show(!isVisible) }
        
    func show(_ show: Bool = true)
    {
        if show
        {
            makeKeyAndOrderFront(NSApp)
            NSApp.activate(ignoringOtherApps: true)
        }
        else
        {
            orderOut(self)
        }
    }
}
