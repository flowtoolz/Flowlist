import AppKit

class Table: NSTableView
{
    // MARK: - Keyboard Input
    
    override func keyDown(with event: NSEvent)
    {
        if forward(keyEvent: event)
        {
            nextResponder?.keyDown(with: event)
        }
        else
        {
            super.keyDown(with: event)
        }
    }
    
    private func forward(keyEvent event: NSEvent) -> Bool
    {
        switch event.key
        {
        case .enter: return true
        case .down, .up: return event.cmd
        default: return false
        }
    }
    
    // MARK: - Mouse Input
    
    override func mouseDown(with event: NSEvent)
    {
        super.mouseDown(with: event)
        nextResponder?.mouseDown(with: event)
    }
}
