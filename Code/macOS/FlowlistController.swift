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
        menu.set(window: mainWindow)
        mainWindow.delegate = self
        mainWindow.show()
    }
    
    func applicationWillTerminate(_ notification: Notification)
    {
        store.save()
    }
    
    // MARK: - Window Delegate
    
    func windowDidResize(_ notification: Notification)
    {
        mainViewController.didResize()
    }
    
    func windowDidEndLiveResize(_ notification: Notification)
    {
        mainWindow.didEndLiveResize()
    }
    
    func windowWillEnterFullScreen(_ notification: Notification)
    {
        menu.windowChangesFullscreen(to: true)
    }
    
    func windowDidEnterFullScreen(_ notification: Notification)
    {
        mainWindow.didEndLiveResize()
    }

    func windowDidExitFullScreen(_ notification: Notification)
    {
        mainWindow.didEndLiveResize()
        menu.windowChangesFullscreen(to: false)
    }
    
    func windowDidResignKey(_ notification: Notification)
    {
        store.save()
    }
    
    // MARK: - Menu & Mindow
    
    private let menu = Menu()
    
    private lazy var mainWindow: Window = Window(with: mainViewController,
                                                 color: Color.gray(brightness: 0.92 * 0.92).nsColor)
    
    private let mainViewController = ViewController()
}
