import AppKit
import SwiftyToolz

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate
{
    // MARK: - App Life Cycle
    
    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        store.load()
        
        if setupWindow() { showWindow() }
    }
    
    func windowDidBecomeKey(_ notification: Notification)
    {
        log("window did become key")
    }
    
    func windowDidBecomeMain(_ notification: Notification)
    {
        log("window did become main")
    }
    
    func windowWillClose(_ notification: Notification)
    {
        quit()
    }
    
    func applicationWillTerminate(_ notification: Notification)
    {
        store.save()
    }
    
    // MARK: - Window
    
    private func setupWindow() -> Bool
    {
        guard let mainScreenFrame = NSScreen.main?.frame else
        {
            log(error: "Couldn't get main screen.")
            return false
        }
        
        window.contentViewController = Controller()
        window.setFrame(CGRect(x: mainScreenFrame.size.width * 0.1,
                               y: mainScreenFrame.size.height * 0.1,
                               width: mainScreenFrame.size.width * 0.8,
                               height: mainScreenFrame.size.height * 0.8),
                        display: true)
        window.styleMask = [.resizable,
                            .titled,
                            .miniaturizable,
                            .closable,
                            .unifiedTitleAndToolbar]
        window.delegate = self
        window.isReleasedWhenClosed = false
        window.title = "Flowlist"
        
        return true
    }
    
    func toggleWindow()
    {
        showWindow(!window.isVisible)
    }
    
    func showWindow(_ show: Bool = true)
    {
        if show
        {
            window.makeKeyAndOrderFront(NSApp)
            
            NSApp.activate(ignoringOtherApps: true)
        }
        else
        {
            window.orderOut(self)
        }
    }
    
    let window = NSWindow()
    
    // MARK: - Quit
    
    func quit()
    {
        NSApp.terminate(nil)
    }
}

autoreleasepool
{
    let app = NSApplication.shared
    let appDelegate = AppDelegate()
    
    app.delegate = appDelegate
    app.run()
}
