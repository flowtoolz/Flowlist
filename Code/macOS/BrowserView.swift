import AppKit

class BrowserView: NSView
{
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        wantsLayer = true
        layer?.backgroundColor = NSColor(calibratedRed: 235.0 / 255.0,
                                         green: 235.0 / 255.0,
                                         blue: 235.0 / 255.0,
                                         alpha: 1.0).cgColor
    }
    
    required init?(coder decoder: NSCoder) { fatalError() }
}
