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
    
    lazy var tableView: Table =
    {
        let view = Table.newAutoLayout()
        
        return view
    }()
}
