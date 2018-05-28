import AppKit
import SwiftObserver
import SwiftyToolz

let keyboard = Keyboard()

class Keyboard: Messenger<NSEvent>
{
    fileprivate init()
    {
        super.init(NSEvent())

        let monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown)
        {
            event in
            
            self.send(event)
            
            return event
        }
        
        if monitor == nil { log(error: "Couldn't get event monitor.") }
    }
}

