import AppKit
import UIToolz
import FoundationToolz
import SwiftyToolz

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
        menu.set(window: window)
        window.delegate = self
        window.show()
    }
    
    func applicationWillTerminate(_ notification: Notification)
    {
        store.save()
    }
    
    // MARK: - Window Delegate
    
    func windowDidResize(_ notification: Notification)
    {
        viewController.didResize()
    }
    
    func windowDidEndLiveResize(_ notification: Notification)
    {
        window.didEndLiveResize()
    }
    
    func windowWillEnterFullScreen(_ notification: Notification)
    {
        menu.windowChangesFullscreen(to: true)
    }
    
    func windowDidEnterFullScreen(_ notification: Notification)
    {
        window.didEndLiveResize()
    }

    func windowDidExitFullScreen(_ notification: Notification)
    {
        window.didEndLiveResize()
        menu.windowChangesFullscreen(to: false)
    }
    
    func windowDidResignKey(_ notification: Notification)
    {
        store.save()
    }
    
    // MARK: - Menu & Mindow
    
    private let menu = Menu()
    
    private lazy var window = Window(with: viewController,
                                     color: Color.windowBackground.nsColor)
    
    private let viewController = ViewController()
}
