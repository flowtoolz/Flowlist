import AppKit
import SwiftObserver
import SwiftyToolz

let keyboard = Keyboard()

class Keyboard: Messenger<NSEvent?>
{
    fileprivate init()
    {
        super.init(nil)
    
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown)
        {
            event in
            
            self.send(event)
            
            return event
        }
        
        if monitor == nil
        {
            log(error: "Couldn't create event monitor for keyboard.")
        }
    }
    
    deinit
    {
        if let monitor = monitor { NSEvent.removeMonitor(monitor) }
    }
    
    private var monitor: Any?
}

