import AppKit
import SwiftyToolz
import UIToolz

extension NSView
{
    func setItemBorder(with radius: Float = .cornerRadius)
    {
        layer?.borderColor = Color.listBorder.cgColor
        layer?.borderWidth = 1.0
        layer?.cornerRadius = radius.cgFloat
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
