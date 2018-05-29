import AppKit
import SwiftObserver
import SwiftyToolz

class ScrollTable: NSScrollView, Observer
{
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        documentView = table
        
        drawsBackground = false
        automaticallyAdjustsContentInsets = false
        contentInsets = NSEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
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
