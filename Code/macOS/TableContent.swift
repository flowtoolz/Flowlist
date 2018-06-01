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
        return Row(with: list?[row])
    }
    
    func tableView(_ tableView: NSTableView,
                   heightOfRow row: Int) -> CGFloat
    {
        return Float.itemHeight.cgFloat
    }
    
    // MARK: - Cells
    
    func tableView(_ tableView: NSTableView,
                   viewFor tableColumn: NSTableColumn?,
                   row: Int) -> NSView?
    {
        let task = list?[row]
        
        let isSelected = list?.selection.isSelected(task) ?? false
        
        if isSelected
        {
            tableView.selectRowIndexes([row], byExtendingSelection: true)
        }
        
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
    
    // MARK: - Selection
    
    func tableViewSelectionDidChange(_ notification: Notification)
    {
        send(.selectionDidChange)
    }
    
    // MARK: - List
    
    func configure(with list: SelectableList?)
    {
        self.list = list
    }
    
    private weak var list: SelectableList?
    
    // MARK: - Observability
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event
    {
        case didNothing, didCreate(taskView: TaskView), selectionDidChange
    }
}
