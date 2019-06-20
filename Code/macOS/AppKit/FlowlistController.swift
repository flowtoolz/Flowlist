import AppKit
import UIToolz
import FoundationToolz
import SwiftObserver
import SwiftyToolz

import UIObserver

class FlowlistController: AppController
{
    // MARK: - Life Cycle
    
    // super.init starts the app run loop, so nothing after super.init will execute
    init() { super.init(withMainMenu: menu) }
    
    deinit { NetworkReachability.shared.stopNotifying(self) }
    
    // MARK: - App Delegate
    
    override func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        super.applicationDidFinishLaunching(aNotification)
        
        NetworkReachability.shared.notifyOfChanges(self)
        {
            [weak self] in self?.networkReachabilityDid(update: $0)
        }
        
        Color.isInDarkMode = systemIsInDarkMode
        
        purchaseController.setup()
        
        window.contentViewController = viewController
        window.backgroundColor = Color.windowBackground.nsColor
        
        Dialog.default = AlertDialog()
        
        observe(darkMode)
        {
            [weak self] _ in
            
            self?.window.backgroundColor = Color.windowBackground.nsColor
        }
        
        registerForPushNotifications()
        registerForICloudAccountChangeNotifications()
        
        storage.appDidLaunch()
    }
    
    override func applicationWillBecomeActive(_ notification: Notification)
    {
        super.applicationWillBecomeActive(notification)
        
        menu.set(window: window)
    }
    
    func applicationWillTerminate(_ notification: Notification)
    {
        storage.appWillTerminate()
        fileLogger.saveLogsToFile()
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
        storage.windowLostFocus()
        fileLogger.saveLogsToFile()
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
        log(warning: "Without push notifications, Flowlist on this device will be unaware of edits you make on other devices. Please restart Flowlist to retry registration.\n\nError message: \(error.readable.message)",
            title: "Couldn't Register for Push Notifications",
            forUser: true)
    }
    
    func application(_ application: NSApplication,
                     didReceiveRemoteNotification userInfo: [String : Any])
    {
        StorageController.shared.database.handlePushNotification(with: userInfo)
    }
    
    private func registerForICloudAccountChangeNotifications()
    {
        let name = Notification.Name.CKAccountChanged
        let center = NotificationCenter.default
        
        center.addObserver(self,
                           selector: #selector(iCloudAccountDidChange),
                           name: name,
                           object: nil)
    }
    
    // MARK: - Storage
    
    @objc private func iCloudAccountDidChange()
    {
        storage.databaseAccountDidChange()
    }
    
    private func networkReachabilityDid(update: NetworkReachability.Update)
    {
        switch update
        {
        case .noInternet:
            storage.networkReachabilityDidUpdate(isReachable: false)
        case .expensiveInternet, .fullInternet:
            storage.networkReachabilityDidUpdate(isReachable: true)
        }
    }
    
    var storage: Storage { return StorageController.shared.storage }
    
    // MARK: - Basics
    
    private let menu = Menu()
    private let viewController = ViewController<FlowlistView>()
    private let fileLogger = FileLogger()
}