import AppKit
import SwiftyToolz

class AnimatedTableView: NSTableView
{
    override func scrollRowToVisible(_ row: Int)
    {
        if !scrollAnimatedTo(row: row)
        {
            super.scrollRowToVisible(row)
        }
    }
    
    @discardableResult
    func scrollAnimatedTo(row: Int,
                          completionHandler: (() -> Void)? = nil) -> Bool
    {
        guard row >= 0, row < numberOfRows else
        {
            log(warning: "Tried to scroll to invalid row \(row).")
            return false
        }
        
        guard let scrollView = enclosingScrollView else
        {
            log(warning: "Expected enclosing scroll view but found none.")
            return false
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
            
            completionHandler?()
            
            return nil
        }()
        
        guard let targetPosition = optionalTargetPosition else { return true }
        
        let targetOrigin = NSPoint(x: 0, y: targetPosition)
        
        NSAnimationContext.runAnimationGroup(
            {
                $0.duration = 0.3
                clipView.animator().setBoundsOrigin(targetOrigin)
                scrollView.reflectScrolledClipView(clipView)
            },
            completionHandler: completionHandler
        )
        
        return true
    }
}
