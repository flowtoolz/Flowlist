import AppKit
import SwiftObserver
import SwiftyToolz

class TableContent: NSObject, Observable, NSTableViewDataSource, NSTableViewDelegate
{
    // MARK: - Rows
    
    func numberOfRows(in tableView: NSTableView) -> Int
    {
        return list?.numberOfTasks ?? 0
    }
    
    func tableView(_ tableView: NSTableView,
                   rowViewForRow row: Int) -> NSTableRowView?
    {
        return NSTableRowView(frame: .zero)
    }
    
    func tableView(_ tableView: NSTableView,
                   heightOfRow row: Int) -> CGFloat
    {
        return delegate?.taskViewHeight(at: row) ?? TaskView.heightWithSingleLine
    }
    
    // MARK: - Cells
    
    func tableView(_ tableView: NSTableView,
                   viewFor tableColumn: NSTableColumn?,
                   row: Int) -> NSView?
    {
        guard let task = list?[row] else
        {
            log(error: "Couldn't find task for row \(row) in list \(list?.title.observable?.value ?? "nil").")
            return nil
        }
        
        let taskView = retrieveTaskView(from: tableView).configure(with: task)
        
        taskView?.isSelected = list?.selection.isSelected(task) ?? false
        
        return taskView
    }
    
    private func retrieveTaskView(from tableView: NSTableView) -> TaskView
    {
        guard let dequeuedView = dequeueView(from: tableView) else
        {
            return createTaskView()
        }
        
        guard let dequeuedTaskView = dequeuedView as? TaskView else
        {
            log(error: "Couldn't cast dequeued view to \(TaskView.self)")
            return createTaskView()
        }
        
        return dequeuedTaskView
    }
    
    private func dequeueView(from tableView: NSTableView) -> NSView?
    {
        return tableView.makeView(withIdentifier: TaskView.uiIdentifier,
                                  owner: nil)
    }
    
    private func createTaskView() -> TaskView
    {
        let taskView = TaskView()
        
        send(.didCreate(taskView: taskView))
        
        return taskView
    }
    
    // MARK: - Disable NSTableView Selection
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool
    {
        return false
    }
    
    // MARK: - List
    
    func configure(with list: SelectableList?)
    {
        self.list = list
    }
    
    private weak var list: SelectableList?
    
    // MARK: - Delegate
    
    var delegate: TableContentDelegate?
    
    // MARK: - Observability
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event
    {
        case didNothing, didCreate(taskView: TaskView)
    }
}

protocol TableContentDelegate
{
    func taskViewHeight(at row: Int) -> CGFloat
}
