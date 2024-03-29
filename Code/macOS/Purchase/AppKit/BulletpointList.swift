import AppKit.NSView
import GetLaid
import SwiftUIToolz
import SwiftyToolz

class BulletpointList: NSView
{
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        constrainBulletpoints()
    }
    
    required init?(coder decoder: NSCoder) { nil }
    
    // MARK: - Dark Mode
    
    func adjustToColorMode()
    {
        let image = checkImage
        
        bulletpointIcons.forEach { $0.image = image }
        
        let textColor = NSColor(Color.text)
        
        bulletpointLabels.forEach { $0.textColor = textColor }
    }
    
    // MARK: - Bullet Points
    
    private func constrainBulletpoints()
    {
        bulletpointIcons.forEachIndex
        {
            icon, index in
            
            icon >> left
            icon >> defaultIconSize
            
            let label = bulletpointLabels[index]
            label >> right
            label >> left.offset(27)
            
            if index == 0
            {
                label >> top
            }
            
            if index == bulletpoints.count - 1
            {
                label >> bottom.offset(-10)
            }
            
            if index > 0
            {
                label.top >> bulletpointLabels[index - 1].bottom.offset(20)
            }
            
            icon >> label.top
        }
    }
    
    private let defaultIconSize: CGFloat = 17
    
    private lazy var bulletpointIcons: [Icon] =
    {
        var icons = [Icon]()
        
        bulletpoints.count.times
        {
            icons.append(addForAutoLayout(Icon(with: checkImage)))
        }
        
        return icons
    }()
    
    private var checkImage: NSImage
    {
        Color.isInDarkMode ? checkImageWhite : checkImageBlack
    }
    
    private let checkImageBlack = #imageLiteral(resourceName: "checkbox_checked_pdf")
    private let checkImageWhite = #imageLiteral(resourceName: "checkbox_checked_white")
    
    private lazy var bulletpointLabels: [Label] =
    {
        var labels = [Label]()
        
        bulletpoints.forEach
        {
            let label = addForAutoLayout(Label())
            label.stringValue = $0
            label.textColor = NSColor(Color.text)
            label.font = Font.purchasePanel.nsFont
            label.lineBreakMode = .byWordWrapping
            labels.append(label)
        }
        
        return labels
    }()
    
    private let bulletpoints: [String] =
    [
        "Infinite items, no more trial version info bar",
        "Pay once, use it forever - no subscription",
        "Support the development of more features",
        "Users vote on which features come next. The link is in the Help menu.",
        "Early bird advantage: Get new features as free updates, even when the full version price rises"
    ]
}
