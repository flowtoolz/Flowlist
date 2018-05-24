import AppKit
import SwiftyToolz

class AppController: NSObject, NSApplicationDelegate, NSWindowDelegate
{
    // MARK: - App Life Cycle
    
    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        NSApp.mainMenu = Menu()
        store.load()
        window.show()
    }
    
    func windowWillClose(_ notification: Notification)
    {
        quit()
    }
    
    func applicationWillTerminate(_ notification: Notification)
    {
        store.save()
    }
    
    // MARK: - Basics
    
    private func quit() { NSApp.terminate(nil) }
    
    private lazy var window = Window(delegate: self)
}
