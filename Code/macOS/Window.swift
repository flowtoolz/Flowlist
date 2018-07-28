import AppKit

public class Window: NSWindow
{
    // MARK: - Initialization

    init(with contentViewController: NSViewController?)
    {
        let windowStyle: StyleMask = [.resizable,
                                      .titled,
                                      .miniaturizable,
                                      .closable]
        
        let screenSize = NSScreen.main?.frame.size ?? CGSize(width: 1280,
                                                             height: 800)
        
        let contentRect = CGRect(x: screenSize.width * 0.1,
                                 y: screenSize.height  * 0.1,
                                 width: screenSize.width * 0.8,
                                 height: screenSize.height * 0.8)

        super.init(contentRect: contentRect,
                   styleMask: windowStyle,
                   backing: .buffered,
                   defer: false)
        
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        
        isReleasedWhenClosed = false
        
        collectionBehavior = [.managed, .fullScreenPrimary] // required for macOS 10.10
        
        if let viewController = contentViewController
        {
            self.contentViewController = viewController
            
            setFrame(contentRect, display: false)
        }
    }
    
    // MARK: - Show & Hide
    
    public func toggle() { show(!isVisible) }
    
    public func show(_ show: Bool = true)
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
    
    public override func noResponder(for eventSelector: Selector) {}
}
