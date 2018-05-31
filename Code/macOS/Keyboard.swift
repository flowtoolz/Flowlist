import AppKit
import SwiftObserver
import SwiftyToolz

let keyboard = Keyboard()

class Keyboard: Observable
{
    fileprivate init()
    {
        let monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown)
        {
            [unowned self] event in
            
            self.lastEvent = event
            
            self.send(event)
            
            return event
        }
        
        if monitor == nil { log(error: "Couldn't get event monitor.") }
    }
    
    var latestUpdate: NSEvent { return lastEvent }
    
    private var lastEvent = NSEvent()
}

