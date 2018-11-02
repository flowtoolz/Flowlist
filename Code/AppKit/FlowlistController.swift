import AppKit
import UIToolz
import FoundationToolz
import SwiftObserver
import SwiftyToolz

class FlowlistController: AppController, NSWindowDelegate
{
    // MARK: - Initialization
    
    init()
    {
        Log.prefix = "FLOWLIST" // use "flowlist:" as console filter
        
        super.init(withMainMenu: menu)
    }
    
    // MARK: - App Delegate
    
    override func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        super.applicationDidFinishLaunching(aNotification)

        purchaseController.setup()
        
        observeSystemAppearance()
        
        observe(darkMode)
        {
            [weak self] _ in
            
            self?.window.backgroundColor = Color.windowBackground.nsColor
        }
        
        registerForPushNotifications()
        
        storageController.appDidLaunch()
    }
    
    func applicationWillBecomeActive(_ notification: Notification)
    {
        menu.set(window: window)
        window.delegate = self
        window.show()
    }
    
    func applicationWillTerminate(_ notification: Notification)
    {
        storageController.appWillTerminate()
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
        storageController.windowLostFocus()
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
    
    // MARK: - Push Notifications
    
    func application(_ application: NSApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error)
    {
        log(warning: "Without push notifications, Flowlist on this device will be unaware of edits you make on other devices. Please restart Flowlist to retry registration.\n\nError message: \(error.localizedDescription)",
            title: "Couldn't Register for Push Notifications",
            forUser: true)
    }
    
    func application(_ application: NSApplication,
                     didReceiveRemoteNotification userInfo: [String : Any])
    {
        database.didReceiveRemoteNotification(with: userInfo)
    }
    
    // MARK: - Basics
    
    private let menu = Menu()
    
    private lazy var window = Window(viewController: viewController,
                                     color: Color.windowBackground.nsColor)
    
    private let viewController = FlowlistViewController()
    
    private let storageController = StorageController(with: database,
                                                      store: Store.shared)
}
