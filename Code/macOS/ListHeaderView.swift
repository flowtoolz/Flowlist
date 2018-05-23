import AppKit

class ListHeaderView: NSView
{
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        applyItemStyle()
    }
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
    override func draw(_ dirtyRect: NSRect)
    {
        NSColor.white.setFill()
        
        let selectionPath = NSBezierPath(roundedRect: dirtyRect,
                                         xRadius: 4,
                                         yRadius: 4)
        
        selectionPath.fill()
    }
}
