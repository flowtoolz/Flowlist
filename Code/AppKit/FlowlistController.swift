import AppKit
import UIToolz
import FoundationToolz
import SwiftObserver
import SwiftyToolz

class FlowlistController: AppController
{
    // MARK: - Initialization
    
    init() { super.init(withMainMenu: menu) }
    
    // MARK: - App Delegate
    
    override func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        super.applicationDidFinishLaunching(aNotification)
        
        Color.isInDarkMode = systemIsInDarkMode
        
        purchaseController.setup()
        
        window.contentViewController = viewController
        window.backgroundColor = Color.windowBackground.nsColor
        
        observe(darkMode)
        {
            [weak self] _ in
            
            self?.window.backgroundColor = Color.windowBackground.nsColor
        }
        
        registerForPushNotifications()
        registerForICloudStatusChangeNotifications()
        
        StorageController.shared.storage.appDidLaunch()
    }
    
    override func applicationWillBecomeActive(_ notification: Notification)
    {
        super.applicationWillBecomeActive(notification)
        
        menu.set(window: window)
    }
    
    func applicationWillTerminate(_ notification: Notification)
    {
        StorageController.shared.storage.appWillTerminate()
    }
    
    // MARK: - Window Delegate
    
    func windowDidResize(_ notification: Notification)
    {
        viewController.contentView.didResize()
    }
    
    func windowWillEnterFullScreen(_ notification: Notification)
    {
        menu.windowChangesFullscreen(to: true)
    }
    
    override func windowDidExitFullScreen(_ notification: Notification)
    {
        super.windowDidExitFullScreen(notification)
        
        menu.windowChangesFullscreen(to: false)
    }
    
    func windowDidResignKey(_ notification: Notification)
    {
        StorageController.shared.storage.windowLostFocus()
    }
    
    // MARK: - Adjust to OSX Dark Mode Setting
    
    override func systemDidChangeColorMode(dark: Bool)
    {
        Color.isInDarkMode = dark
    }
    
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
        let iCloudDatabase = StorageController.shared.iCloudDatabase
            
        iCloudDatabase.handlePushNotification(with: userInfo)
    }
    
    private func registerForICloudStatusChangeNotifications()
    {
        let name = Notification.Name.CKAccountChanged
        let center = NotificationCenter.default
        
        center.addObserver(self,
                           selector: #selector(iCloudStatusChanged),
                           name: name,
                           object: nil)
    }
    
    @objc private func iCloudStatusChanged()
    {
        DispatchQueue.main.async
        {
            let storage = StorageController.shared.storage
                
            storage.databaseAvailabilityMayHaveChanged()
        }
    }
    
    // MARK: - Basics
    
    private let menu = Menu()
    private let viewController = ViewController<FlowlistView>()
}
