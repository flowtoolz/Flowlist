import AppKit
import SwiftyToolz
import UIToolz

extension NSView
{
    func setItemBorder()
    {
        wantsLayer = true
        layer?.borderColor = Color.border.cgColor
        layer?.borderWidth = 1.0
        layer?.cornerRadius = Float.cornerRadius.cgFloat
    }
    
    func drawItemBackground(with color: NSColor, in rect: NSRect)
    {
        color.setFill()
        
        let selectionPath = NSBezierPath(roundedRect: rect,
                                         xRadius: Float.cornerRadius.cgFloat,
                                         yRadius: Float.cornerRadius.cgFloat)
        
        selectionPath.fill()
    }
}
