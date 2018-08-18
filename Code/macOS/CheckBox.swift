import AppKit

class CheckBox: NSButton
{
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        bezelStyle = .regularSquare
        imagePosition = .imageOnly
        imageScaling = .scaleProportionallyUpOrDown
        image = CheckBox.imageEmpty
        isBordered = false
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Update
    
    func update(with state: TaskState?)
    {
        image = image(for: state)
    }
    
    // MARK: - Image
    
    static var size = imageEmpty.size
    
    private func image(for state: TaskState?) -> NSImage
    {
        guard let state = state else { return CheckBox.imageEmpty }
        
        switch state
        {
        case .inProgress: return CheckBox.imageInProgress
        case .done, .trashed: return CheckBox.imageChecked
        }
    }
    
    private static let imageEmpty = #imageLiteral(resourceName: "checkbox_unchecked_pdf")
    private static let imageChecked = #imageLiteral(resourceName: "checkbox_checked_pdf")
    private static let imageInProgress = #imageLiteral(resourceName: "play_pdf")
}
