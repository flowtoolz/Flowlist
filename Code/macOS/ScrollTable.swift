import AppKit
import SwiftyToolz

class ScrollTable: NSScrollView
{
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        documentView = table
        
        drawsBackground = false
        automaticallyAdjustsContentInsets = false
        contentInsets = NSEdgeInsetsZero
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Configuration
    
    func configure(with list: SelectableList)
    {
        self.list = list
    
        table.configure(with: list)
    }
    
    // MARK: - Basics
    
    let table = Table()
    
    private weak var list: SelectableList?
}
