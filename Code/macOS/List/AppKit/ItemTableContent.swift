import AppKit
import UIToolz
import SwiftObserver
import SwiftyToolz

class ItemTableContent: NSObject, SwiftObserver.Observable, NSTableViewDataSource, NSTableViewDelegate
{
    // MARK: - Rows
    
    func numberOfRows(in tableView: NSTableView) -> Int
    {
        (list?.count ?? 0) + 1
    }
    
    func tableView(_ tableView: NSTableView,
                   rowViewForRow row: Int) -> NSTableRowView?
    {
        Row()
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat
    {
        if row >= (list?.count ?? 0)
        {
            return ItemView.heightWithSingleLine / 2
        }
        
        return delegate?.itemViewHeight(at: row) ?? ItemView.heightWithSingleLine
    }
    
    // MARK: - Cells
    
    func tableView(_ tableView: NSTableView,
                   viewFor tableColumn: NSTableColumn?,
                   row: Int) -> NSView?
    {
        guard let list = list, row < list.count, tableView.numberOfRows > 1 else
        {
            return tableView.makeView(withIdentifier: Spacer.uiIdentifier,
                                      owner: nil) ?? Spacer()
        }
        
        guard let item = list[row] else
        {
            log(error: "Couldn't find item for row \(row) in list \(list.title.value ?? "nil").")
            return nil
        }
        
        let itemView = retrieveItemView(from: tableView)
        
        itemView.configure(with: item)
        
        return itemView
    }
    
    private func retrieveItemView(from tableView: NSTableView) -> ItemView
    {
        guard let dequeuedView = dequeueView(from: tableView) else
        {
            return createItemView()
        }
        
        guard let dequeuedItemView = dequeuedView as? ItemView else
        {
            log(error: "Couldn't cast dequeued view to \(ItemView.self)")
            return createItemView()
        }
        
        return dequeuedItemView
    }
    
    private func dequeueView(from tableView: NSTableView) -> NSView?
    {
        tableView.makeView(withIdentifier: ItemView.uiIdentifier, owner: nil)
    }
    
    private func createItemView() -> ItemView
    {
        let itemView = ItemView()
        
        send(.didCreate(itemView: itemView))
        
        return itemView
    }
    
    // MARK: - Disable NSTableView Selection
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool { false }
    
    // MARK: - List
    
    func configure(with list: List?)
    {
        self.list = list
    }
    
    private weak var list: List?
    
    // MARK: - Delegate
    
    var delegate: TableContentDelegate?
    
    // MARK: - Observability
    
    let messenger = Messenger<Event>()
    enum Event { case didCreate(itemView: ItemView) }
}

protocol TableContentDelegate
{
    func itemViewHeight(at row: Int) -> CGFloat
}
