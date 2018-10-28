import AppKit
import UIToolz
import FoundationToolz
import SwiftObserver
import SwiftyToolz

class FlowlistController: AppController, Observer, NSWindowDelegate
{
    // MARK: - Initialization
    
    init() { super.init(withMainMenu: menu) }
    
    // MARK: - App Delegate
    
    override func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        super.applicationDidFinishLaunching(aNotification)

        fullVersionPurchaseController.setup()
        store.load()
        
        observeSystemAppearance()
        
        observe(darkMode)
        {
            [weak self] _ in
            
            self?.window.backgroundColor = Color.windowBackground.nsColor
        }
        
        NSApp.registerForRemoteNotifications(matching: [.badge, .sound, .alert])
        
        itemDatabase.test()
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
    
    // MARK: - Adjust to OSX Dark Mode Setting
    
    private func observeSystemAppearance()
    {
        guard #available(OSX 10.14, *) else { return }
        
        adjustToSystemAppearance()
        
        appearanceObservation = NSApp.observe(\.effectiveAppearance)
        {
            [weak self] _, _ in self?.adjustToSystemAppearance()
        }
    }
    
    @available(OSX 10.14, *)
    private func adjustToSystemAppearance()
    {
        Color.isInDarkMode = NSApp.effectiveAppearance.name == .darkAqua
    }
    
    private var appearanceObservation: NSKeyValueObservation?
    
    // MARK: - Push Notifications & iCloud
    
    func application(_ application: NSApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error)
    {
        log(error: error.localizedDescription)
    }
    
    func application(_ application: NSApplication,
                     didReceiveRemoteNotification userInfo: [String : Any])
    {
        itemDatabase.didReceiveRemoteNotification(with: userInfo)
    }
    
    // MARK: - Menu & Mindow
    
    private let menu = Menu()
    
    private lazy var window = Window(with: viewController,
                                     color: Color.windowBackground.nsColor)
    
    private let viewController = ViewController()
}
