import AppKit
import SwiftyToolz

class AnimatedTableView: NSTableView
{
    override func scrollRowToVisible(_ row: Int)
    {
        guard row >= 0, row < numberOfRows else
        {
            log(warning: "Tried to scroll to invalid row \(row).")
            return
        }
        
        guard let scrollView = enclosingScrollView else
        {
            log(warning: "Expected enclosing scroll view but found none.")
            super.scrollRowToVisible(row)
            return
        }
        
        let clipView = scrollView.contentView
        
        let optionalTargetPosition: CGFloat? =
        {
            let rowRect = rect(ofRow: row)
            let clipBounds = clipView.bounds
            
            if rowRect.origin.y < clipBounds.origin.y
            {
                return max(0, rowRect.origin.y)
            }
            else if rowRect.origin.y + rowRect.size.height >
                clipBounds.origin.y + clipBounds.size.height
            {
                return (rowRect.origin.y + rowRect.size.height) - clipBounds.size.height
            }
            
            return nil
        }()
        
        guard let targetPosition = optionalTargetPosition else { return }
        
        let targetOrigin = NSPoint(x: 0, y: targetPosition)
        
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 0.3
        
        clipView.animator().setBoundsOrigin(targetOrigin)
        scrollView.reflectScrolledClipView(clipView)
        
        NSAnimationContext.endGrouping()
    }
}
