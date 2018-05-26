import AppKit

class AppController: NSObject, NSApplicationDelegate, NSWindowDelegate
{
    // MARK: - App Life Cycle
    
    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        NSApp.enableRelaunchOnLogin()
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

    func windowWillClose(_ notification: Notification)
    {
        NSApp.terminate(self)
    }
    
    func windowDidResignKey(_ notification: Notification)
    {
        store.save()
    }
    
    func applicationWillTerminate(_ notification: Notification)
    {
        store.save()
    }
    
    // MARK: - Basics
    
    private let menu = Menu()
    private lazy var window = Window(delegate: self)
}
