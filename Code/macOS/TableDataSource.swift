import AppKit
import SwiftObserver
import SwiftyToolz

class TableDataSource: NSObject, Observable, NSTableViewDataSource
{
    // MARK: - Data Source
    
    func numberOfRows(in tableView: NSTableView) -> Int
    {
        return list?.numberOfTasks ?? 0
    }
    
    // MARK: - Delegate: Rows
    
    func tableView(_ tableView: NSTableView,
                   rowViewForRow row: Int) -> NSTableRowView?
    {
        return Row(with: list?.task(at: row))
    }
    
    // MARK: - Delegate: Cells
    
    func tableView(_ tableView: NSTableView,
                   viewFor tableColumn: NSTableColumn?,
                   row: Int) -> NSView?
    {
        let task = list?.task(at: row)
        
        return retrieveTaskView(from: tableView).configure(with: task)
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
    
    // MARK: - List
    
    weak var list: SelectableList?
    
    // MARK: - Observability
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event { case didNothing, didCreate(taskView: TaskView) }
}
