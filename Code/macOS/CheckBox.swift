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
        isBordered = false
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Configuration
    
    func configure(with state: TaskState?, whiteColorMode white: Bool)
    {
        taskState = state
        isWhite = white
        updateImage()
    }
    
    func setColorMode(white: Bool)
    {
        isWhite = white
        updateImage()
    }
    
    func update(with state: TaskState?)
    {
        taskState = state
        updateImage()
    }
    
    // MARK: - Update Image
    
    private func updateImage()
    {
        image = CheckBox.image(for: taskState, white: isWhite)
    }
    
    private var taskState: TaskState?
    private var isWhite = false
    
    // MARK: - Get Image
    
    private static func image(for state: TaskState?,
                              white: Bool) -> NSImage
    {
        guard let state = state else
        {
            return white ? imageEmptyWhite : imageEmpty
        }
        
        switch state
        {
        case .inProgress:
            return white ? imageInProgressWhite : imageInProgress
            
        case .done, .trashed:
            return white ? imageCheckedWhite : imageChecked
        }
    }
    
    private static let imageEmpty = #imageLiteral(resourceName: "checkbox_unchecked_pdf")
    private static let imageEmptyWhite = #imageLiteral(resourceName: "checkbox_unchecked_white")
    private static let imageChecked = #imageLiteral(resourceName: "checkbox_checked_pdf")
    private static let imageCheckedWhite = #imageLiteral(resourceName: "checkbox_checked_white")
    private static let imageInProgress = #imageLiteral(resourceName: "play_pdf")
    private static let imageInProgressWhite = #imageLiteral(resourceName: "play_white")
}
