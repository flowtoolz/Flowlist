import AppKit
import UIToolz
import SwiftObserver
import SwiftyToolz

class TableContent: NSObject, Observable, NSTableViewDataSource, NSTableViewDelegate
{
    // MARK: - Rows
    
    func numberOfRows(in tableView: NSTableView) -> Int
    {
        return (list?.count ?? 0) + 1
    }
    
    func tableView(_ tableView: NSTableView,
                   rowViewForRow row: Int) -> NSTableRowView?
    {
        return Row()
    }
    
    func tableView(_ tableView: NSTableView,
                   heightOfRow row: Int) -> CGFloat
    {
        if row >= (list?.count ?? 0)
        {
            return ItemView.heightWithSingleLine / 2
        }
        
        return delegate?.taskViewHeight(at: row) ?? ItemView.heightWithSingleLine
    }
    
    // MARK: - Cells
    
    func tableView(_ tableView: NSTableView,
                   viewFor tableColumn: NSTableColumn?,
                   row: Int) -> NSView?
    {
        guard let list = list else { return nil }
        
        guard row < list.count else
        {
            return tableView.makeView(withIdentifier: Spacer.uiIdentifier,
                                      owner: nil) ?? Spacer()
        }
        
        guard let task = list[row] else
        {
            log(error: "Couldn't find task for row \(row) in list \(list.title.observable?.value ?? "nil").")
            return nil
        }
        
        let taskView = retrieveTaskView(from: tableView)
        
        taskView.configure(with: task)
        
        return taskView
    }
    
    private func retrieveTaskView(from tableView: NSTableView) -> ItemView
    {
        guard let dequeuedView = dequeueView(from: tableView) else
        {
            return createTaskView()
        }
        
        guard let dequeuedTaskView = dequeuedView as? ItemView else
        {
            log(error: "Couldn't cast dequeued view to \(ItemView.self)")
            return createTaskView()
        }
        
        return dequeuedTaskView
    }
    
    private func dequeueView(from tableView: NSTableView) -> NSView?
    {
        return tableView.makeView(withIdentifier: ItemView.uiIdentifier,
                                  owner: nil)
    }
    
    private func createTaskView() -> ItemView
    {
        let taskView = ItemView()
        
        send(.didCreate(taskView: taskView))
        
        return taskView
    }
    
    // MARK: - Disable NSTableView Selection
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool
    {
        return false
    }
    
    // MARK: - List
    
    func configure(with list: List?)
    {
        self.list = list
    }
    
    private weak var list: List?
    
    // MARK: - Delegate
    
    var delegate: TableContentDelegate?
    
    // MARK: - Observability
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event
    {
        case didNothing, didCreate(taskView: ItemView)
    }
}

protocol TableContentDelegate
{
    func taskViewHeight(at row: Int) -> CGFloat
}
