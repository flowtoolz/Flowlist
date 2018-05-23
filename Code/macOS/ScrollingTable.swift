import AppKit

class ScrollingTable: NSScrollView
{
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: NSZeroRect)
        
        documentView = tableView
        
        drawsBackground = false
        automaticallyAdjustsContentInsets = false
        contentInsets = NSEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Configuration
    
    func configure(with list: SelectableList)
    {
        self.list = list
        
        tableView.configure(with: list)
    }
    
    // MARK: - Editing
    
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
    
    // MARK: - Table View
    
    lazy var tableView: Table =
    {
        let view = Table.newAutoLayout()
        
        return view
    }()
    
    // MARK: - List
    
    private weak var list: SelectableList?
}
