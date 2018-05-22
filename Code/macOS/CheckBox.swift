import AppKit

class CheckBox: NSButton
{
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        bezelStyle = .regularSquare
        title = ""
        imageScaling = .scaleNone
        image = CheckBox.imageEmpty
        isBordered = false
        layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    required init?(coder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    func image(_ checked: Bool) -> NSImage?
    {
        return checked ? CheckBox.imageChecked : CheckBox.imageEmpty
    }
    
    private static let imageEmpty = #imageLiteral(resourceName: "checkbox_unchecked")
    private static let imageChecked = #imageLiteral(resourceName: "checkbox_checked")
}
