import AppKit
import FoundationToolz

class FlowlistController: AppController, NSWindowDelegate
{
    // MARK: - Initialization
    
    init() { super.init(withMainMenu: menu) }
    
    // MARK: - App Delegate
    
    override func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        super.applicationDidFinishLaunching(aNotification)
        
        fullVersionPurchaseController.setup()
        store.load()
    }
    
    func applicationWillBecomeActive(_ notification: Notification)
    {
        mainWindow.delegate = self
        mainWindow.show()
    }
    
    func applicationWillTerminate(_ notification: Notification)
    {
        store.save()
    }
    
    // MARK: - Window Delegate
    
    func windowDidEndLiveResize(_ notification: Notification)
    {
        mainWindow.didEndResizing()
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
    
    // MARK: - Menu
    
    private let menu = Menu()
}
