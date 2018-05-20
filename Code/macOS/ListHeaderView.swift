import AppKit

class ListHeaderView: NSView
{
    override func draw(_ dirtyRect: NSRect)
    {
        NSColor.white.setFill()
        
        let selectionPath = NSBezierPath(roundedRect: dirtyRect,
                                         xRadius: 4,
                                         yRadius: 4)
        
        selectionPath.fill()
    }
}
