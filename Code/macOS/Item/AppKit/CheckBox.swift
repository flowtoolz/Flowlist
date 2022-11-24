import AppKit
import GetLaid
import SwiftUIToolz

class CheckBox: Icon
{
    // MARK: - Initialization
    
    init()
    {
        super.init(with: nil)
        
        button >> self
    }
    
    required init?(coder: NSCoder) { nil }
    
    // MARK: - Configuration
    
    func configure(with state: ItemData.State?, white: Bool)
    {
        itemState = state
        isWhite = white
        updateImage()
    }
    
    func set(white: Bool)
    {
        isWhite = white
        updateImage()
    }
    
    func set(state: ItemData.State?)
    {
        itemState = state
        updateImage()
    }
    
    // MARK: - Update Image
    
    private func updateImage()
    {
        image = CheckBox.image(for: itemState, white: isWhite)
    }
    
    private var itemState: ItemData.State?
    private var isWhite = false
    
    // MARK: - Get Image
    
    private static func image(for state: ItemData.State?,
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
    
    // MARK: - Button Overlay
    
    lazy var button: NSButton =
    {
        let btn = addForAutoLayout(NSButton())
        
        btn.bezelStyle = .regularSquare
        btn.isBordered = false
        btn.imagePosition = .imageOnly
        btn.title = ""
        
        return btn
    }()
}
