import AppKit
import SwiftyToolz

class AppController: NSObject, NSApplicationDelegate, NSWindowDelegate
{
    // MARK: - App Life Cycle
    
    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        store.load()
        window.show()
    }
    
    func windowDidBecomeKey(_ notification: Notification)
    {
        log("window did become key")
    }
    
    func windowDidBecomeMain(_ notification: Notification)
    {
        log("window did become main")
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
    
    private lazy var window: Window =
    {
        let w = Window()
        
        w.contentViewController = ViewController()
        w.delegate = self
        w.setupFrame()
        
        return w
    }()
}
