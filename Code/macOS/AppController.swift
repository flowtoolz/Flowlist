import AppKit
import FoundationToolz

class AppController: NSObject, NSApplicationDelegate, NSWindowDelegate
{
    // MARK: - App Life Cycle
    
    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.mainMenu = menu
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
