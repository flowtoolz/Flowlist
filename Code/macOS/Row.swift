import AppKit
import SwiftObserver
import SwiftyToolz

class Row: NSTableRowView, Observer
{
    // MARK: - Life Cycle
    
    init?(with task: Task?)
    {
        guard let task = task else
        {
            log(error: "Cannot create row with nil task.")
            return nil
        }
        
        super.init(frame: .zero)
        
        self.task = task

        observe(task.state) { [weak self] _ in self?.display() }
    }
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
    deinit { stopAllObserving() }
    
    // MARK: - Draw Background
    
    override func drawSelection(in dirtyRect: NSRect)
    {
        let color = Color.flowlistBlue.with(alpha: isEmphasized ? 0.5 : 0.25)
        
        drawBackground(with: color.nsColor)
    }
    
    override func drawBackground(in dirtyRect: NSRect)
    {
        let color: Color = task?.backgroundColor ?? .white
        
        drawBackground(with: color.nsColor)
    }
 
    private func drawBackground(with color: NSColor)
    {
        var drawRect = bounds
        
        let verticalGap = Float.verticalGap.cgFloat
        drawRect.origin.y = verticalGap / 2
        drawRect.size.height -= verticalGap
        
        drawItemBackground(with: color, in: drawRect)
    }
    
    // MARK: - Task
    
    private weak var task: Task?
}
