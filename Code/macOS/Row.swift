import AppKit.NSTableRowView

class Row: NSTableRowView
{
    // MARK: - Initialization
    
    init() { super.init(frame: .zero) }
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
    // MARK: - Draw Background
    
    override func drawBackground(in dirtyRect: NSRect) {}
}
