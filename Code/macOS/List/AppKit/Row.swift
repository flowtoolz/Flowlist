import AppKit.NSTableRowView

// TODO: this only exists to avoid a macOS layout bug. investigate, understand, remove!
class Row: NSTableRowView
{
    // MARK: - Initialization
    
    init()
    {
        super.init(frame: .zero)
        isTargetForDropOperation = false
        draggingDestinationFeedbackStyle = .none
        selectionHighlightStyle = .none
    }
    
    required init?(coder decoder: NSCoder) { nil }
    
    // MARK: - Ensure Nothing Unnecessary is Drawn
    
    override func drawBackground(in dirtyRect: NSRect) {} // this avoids a visual bug
    override func drawSelection(in dirtyRect: NSRect) {}
    override func drawSeparator(in dirtyRect: NSRect) {}
}
