import AppKit
import SwiftyToolz

class AppController: NSObject, NSApplicationDelegate, NSWindowDelegate
{
    // MARK: - App Life Cycle
    
    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        NSApp.mainMenu = menu
        
        store.load()
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
        NSApp.terminate(self)
    }
    
    func applicationWillTerminate(_ notification: Notification)
    {
        store.save()
    }
    
    // MARK: - Basics
    
    private let menu = Menu()
    private lazy var window = Window(delegate: self)
}
