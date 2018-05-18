import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate
{
    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        store.load()
        
        setupWindow()
    }
    
    func applicationWillTerminate(_ notification: Notification)
    {
        store.save()
    }
    
    // MARK: - Window
    
    private func setupWindow()
    {
        window.contentViewController = MainViewController()
        window.styleMask = NSWindow.StyleMask([NSWindow.StyleMask.resizable, NSWindow.StyleMask.titled, NSWindow.StyleMask.miniaturizable, NSWindow.StyleMask.closable, NSWindow.StyleMask.unifiedTitleAndToolbar])
        
        let frame = NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 1280, height: 960)
        
        window.setFrame(CGRect(x: frame.size.width / 5,
                               y: frame.size.height / 5,
                               width: frame.size.width * 0.6,
                               height: frame.size.height * 0.6),
                        display: true)
        
        window.delegate = self
        window.isReleasedWhenClosed = false
        window.title = "Flowlist"
        
        //window.toolbar = toolbar
        showWindow()
    }
    
//    private lazy var toolbar: NSToolbar =
//    {
//        let bar = NSToolbar(identifier: "ToolbarIdentifier")
//        
//        bar.sizeMode = .small
//        
//        return bar
//    }()
    
    func windowWillClose(_ notification: Notification)
    {
        quit()
    }
    
    func toggleWindow()
    {
        if window.isVisible
        {
            hideWindow()
        }
        else
        {
            showWindow()
        }
    }
    
    func showWindow()
    {
        window.makeKeyAndOrderFront(NSApp)
        
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func hideWindow()
    {
        window.orderOut(self)
    }
    
    func windowDidBecomeKey(_ notification: Notification)
    {
        print("did become key")
        
        logFirstResponder()
        setupMenuOptions()
    }
    
    func windowDidBecomeMain(_ notification: Notification)
    {
        print("did become main")
    }
    
    let window = NSWindow()
    
    @objc func quit()
    {
        NSApp.terminate(nil)
    }
    
    // MARK: - Menu
    
    func setupMenuOptions()
    {
        let quitOption = NSMenuItem(title: "Quit",
                                    action: #selector(quit),
                                    keyEquivalent: "")

        if NSApp.mainMenu == nil
        {
            NSApp.mainMenu = NSMenu(title: "Menu")
        }
        
        NSApp.mainMenu?.addItem(quitOption)
    }
}

autoreleasepool
{
    let app = NSApplication.shared
    let appDelegate = AppDelegate()
    
    app.delegate = appDelegate
    app.run()
}
