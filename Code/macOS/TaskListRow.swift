import AppKit
import SwiftObserver

class TaskListRow: NSTableRowView, Observer
{
    init(with task: Task?)
    {
        super.init(frame: .zero)
        
        self.task = task
        
        if let task = task
        {
            observe(task.state) { [weak self] _ in self?.display() }
        }
    }
    
    required init?(coder decoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit { stopObserving(task) }
    
    override func drawSelection(in dirtyRect: NSRect)
    {
        let color = TaskView.selectionColor.withAlphaComponent(isEmphasized ? 1 : 0.5)
        
        drawBackground(with: color)
    }
    
    override func drawBackground(in dirtyRect: NSRect)
    {
        let color = task?.isDone ?? false ? TaskView.doneColor : NSColor.white
        
        drawBackground(with: color)
    }
 
    private func drawBackground(with color: NSColor)
    {
        var drawRect = bounds
        
        drawRect.origin.y = TaskView.verticalGap / 2
        drawRect.size.height -= TaskView.verticalGap
        
        color.setFill()
        
        let selectionPath = NSBezierPath(roundedRect: drawRect,
                                         xRadius: 4,
                                         yRadius: 4)
        
        selectionPath.fill()
    }
    
    private weak var task: Task?
}
