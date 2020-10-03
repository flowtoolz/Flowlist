import AppKit
import UIToolz
import FoundationToolz
import SwiftObserver
import SwiftyToolz

import UIObserver

@main
class FlowlistAppController: AppController
{
    // MARK: - Life Cycle
    
    static func main() { instance.startApp() }
    
    private static let instance = FlowlistAppController()
    
    init()
    {
        super.init(appView: flowlistView, appMenu: flowlistMenu)
    }
    
    // MARK: - App Life Cycle
    
    override func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        super.applicationDidFinishLaunching(aNotification)
        
        Color.isInDarkMode = systemIsInDarkMode
        
        purchaseController.setup()
        
        window.backgroundColor = Color.windowBackground.nsColor
        
        Dialog.default = AlertDialog()
        
        observe(Color.darkMode)
        {
            [weak self] _ in
            
            self?.window.backgroundColor = Color.windowBackground.nsColor
        }
        
        registerForPushNotifications()
        registerForICloudAccountChangeNotifications()
        
        StorageController.shared.appDidLaunch()
    }
    
    override func applicationWillBecomeActive(_ notification: Notification)
    {
        super.applicationWillBecomeActive(notification)
        
        flowlistMenu.set(window: window)
    }
    
    func applicationWillTerminate(_ notification: Notification)
    {
        fileLogger.saveLogsToFile()
    }
    
    // MARK: - Window Delegate
    
    func windowDidEndLiveResize(_ notification: Notification)
    {
        flowlistView.windowDidEndResizing()
    }
    
    func windowDidResize(_ notification: Notification)
    {
        flowlistView.windowDidResize()
    }
    
    func windowWillEnterFullScreen(_ notification: Notification)
    {
        flowlistMenu.windowChangesFullscreen(to: true)
    }
    
    func windowDidEnterFullScreen(_ notification: Notification)
    {
        flowlistView.windowDidEndResizing()
    }
    
    func windowDidExitFullScreen(_ notification: Notification)
    {
        flowlistMenu.windowChangesFullscreen(to: false)
        flowlistView.windowDidEndResizing()
    }
    
    func windowDidResignKey(_ notification: Notification)
    {
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
        log(warning: "Without push notifications, Flowlist on this device will be unaware of edits you make on other devices. Please restart Flowlist to retry registration.\n\nError message: \(error.localizedDescription)",
            title: "Couldn't Register for Push Notifications",
            forUser: true)
    }
    
    func application(_ application: NSApplication,
                     didReceiveRemoteNotification userInfo: JSON)
    {
        CKRecordDatabase.shared.handleDatabaseNotification(with: userInfo)
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
        StorageController.shared.cloudKitAccountDidChange()
    }
    
    // MARK: - Basics
    
    private let flowlistMenu = FlowlistMenu()
    private let flowlistView = FlowlistView()
    private let fileLogger = FileLogger(URL.flowlistDirectory.appendingPathComponent("flowlist-log.txt"))
}
