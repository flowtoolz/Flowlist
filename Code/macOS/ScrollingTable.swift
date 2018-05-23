import AppKit

class ScrollingTable: NSScrollView
{
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        documentView = tableView
        
        drawsBackground = false
        automaticallyAdjustsContentInsets = false
        contentInsets = NSEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func startEditing(at index: Int)
    {
        guard index < tableView.numberOfRows else { return }
        
        if index == 0
        {
            jumpToTop()
        }
        else
        {
            tableView.scrollRowToVisible(index)
        }
        
        if let cell = tableView.view(atColumn: 0,
                                     row: index,
                                     makeIfNecessary: false) as? TaskView
        {
            cell.editTitle()
        }
    }
    
    func jumpToTop()
    {
        var newOrigin = contentView.bounds.origin
        
        newOrigin.y = 0
        
        contentView.setBoundsOrigin(newOrigin)
    }
    
    lazy var tableView: Table =
    {
        let view = Table.newAutoLayout()
        
        return view
    }()
}
