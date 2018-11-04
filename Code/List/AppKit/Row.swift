import AppKit.NSTableRowView

// TODO: this only exists to avoid a macOS layout bug. investigate, understand, remove!
class Row: NSTableRowView
{
    // MARK: - Initialization
    
    init() { super.init(frame: .zero) }
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
    // MARK: - Draw Background
    
    override func drawBackground(in dirtyRect: NSRect) {}
}
