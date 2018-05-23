import AppKit
import SwiftObserver
import SwiftyToolz

class Row: NSTableRowView, Observer
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
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
    deinit { stopObserving(task) }
    
    override func drawSelection(in dirtyRect: NSRect)
    {
        let color = Color.selected.nsColor.withAlphaComponent(isEmphasized ? 1 : 0.5)
        
        drawBackground(with: color)
    }
    
    override func drawBackground(in dirtyRect: NSRect)
    {
        let color = task?.isDone ?? false ? Color.done.nsColor : NSColor.white
        
        drawBackground(with: color)
    }
 
    private func drawBackground(with color: NSColor)
    {
        var drawRect = bounds
        
        let verticalGap = Float.verticalGap.cgFloat
        drawRect.origin.y = verticalGap / 2
        drawRect.size.height -= verticalGap
        
        drawItemBackground(with: color, in: drawRect)
    }
    
    private weak var task: Task?
}
