import AppKit

class CheckBox: NSButton
{
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        bezelStyle = .regularSquare
        imageScaling = .scaleNone
        image = CheckBox.imageEmpty
        isBordered = false
        layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Update
    
    func update(with state: Task.State?)
    {
        image = image(checked: state == .done)
    }
    
    // MARK: - Image
    
    private func image(checked: Bool) -> NSImage
    {
        return checked ? CheckBox.imageChecked : CheckBox.imageEmpty
    }
    
    private static let imageEmpty = #imageLiteral(resourceName: "checkbox_unchecked")
    private static let imageChecked = #imageLiteral(resourceName: "checkbox_checked")
}
