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
    
    func update(with state: TaskState?)
    {
        image = image(for: state)
    }
    
    // MARK: - Image
    
    private func image(for state: TaskState?) -> NSImage
    {
        guard let state = state else { return CheckBox.imageEmpty }
        
        switch state
        {
        case .done, .trashed: return CheckBox.imageChecked
        case .inProgress: return CheckBox.imageThick
        }
    }
    
    private static let imageEmpty = #imageLiteral(resourceName: "checkbox_unchecked")
    private static let imageChecked = #imageLiteral(resourceName: "checkbox_checked")
    private static let imageThick = #imageLiteral(resourceName: "checkbox_thick")
}
