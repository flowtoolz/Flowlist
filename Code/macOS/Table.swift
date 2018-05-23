import AppKit

class Table: NSTableView
{
    override func keyDown(with event: NSEvent)
    {
        //Swift.print("\(event.keyCode)")
        
        switch event.keyCode
        {
        case 36:
            nextResponder?.keyDown(with: event)
        case 125, 126:
            if event.modifierFlags.contains(NSEvent.ModifierFlags.command)
            {
                nextResponder?.keyDown(with: event)
            }
            else
            {
                super.keyDown(with: event)
            }
        default:
            super.keyDown(with: event)
        }
    }
    
    override func mouseDown(with event: NSEvent)
    {
        super.mouseDown(with: event)
        
        taskListDelegate?.taskListTableViewWasClicked(self)
    }
    
    weak var taskListDelegate: TaskListTableViewDelegate?
}

protocol TaskListTableViewDelegate: AnyObject
{
    func taskListTableViewWasClicked(_ view: Table)
}
