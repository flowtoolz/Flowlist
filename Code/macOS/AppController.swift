import AppKit
import FoundationToolz

class AppController: NSObject, NSApplicationDelegate, NSWindowDelegate
{
    // MARK: - Initialization
    
    override init()
    {
        super.init()
        
        initApp()
        runApp()
    }
    
    private func initApp() { _ = NSApplication.shared }
    
    // MARK: - App Life Cycle
    
    private func runApp()
    {
        NSApp.mainMenu = menu // must be set before delegate on macOS 10.10
        NSApp.delegate = self
        NSApp.run()
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        NSApp.activate(ignoringOtherApps: true)
        
        fullVersionPurchaseController.setup()
        networkReachability.setup()
        store.load()
    }
    
    func applicationWillBecomeActive(_ notification: Notification)
    {
        window.show()
    }
    
    func windowWillEnterFullScreen(_ notification: Notification)
    {
        menu.windowChangesFullscreen(to: true)
    }

    func windowDidExitFullScreen(_ notification: Notification)
    {
        menu.windowChangesFullscreen(to: false)
    }
    
    func windowDidResignKey(_ notification: Notification)
    {
        store.save()
    }
    
    func windowWillClose(_ notification: Notification)
    {
        NSApp.hide(self)
    }
    
    func applicationWillTerminate(_ notification: Notification)
    {
        store.save()
    }
    
    // MARK: - Basics
    
    private let menu = Menu()
    private lazy var window = Window(delegate: self)
}
