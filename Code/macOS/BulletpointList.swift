import AppKit.NSView
import UIToolz
import SwiftyToolz

class BulletpointList: NSView
{
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        constrainBulletpoints()
    }
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
    private func constrainBulletpoints()
    {
        for index in 0 ..< bulletpointLabels.count
        {
            let icon = bulletpointIcons[index]
            icon.constrainLeftToParent()
            icon.constrainSize(to: defaultIconSize, defaultIconSize)
            
            let label = bulletpointLabels[index]
            label.constrainRightToParent()
            label.constrainLeftToParent(inset: 27)
            
            if index == 0
            {
                label.constrainTopToParent()
            }
            
            if index == bulletpoints.count - 1
            {
                label.constrainBottomToParent(inset: 10)
            }
            
            if index > 0
            {
                label.constrain(below: bulletpointLabels[index - 1], gap: 20)
            }
            
            icon.constrainTop(to: label)
        }
    }
    
    private let defaultIconSize: CGFloat = 17
    
    private lazy var bulletpointIcons: [Icon] =
    {
        var icons = [Icon]()
        
        for _ in bulletpoints
        {
            icons.append(addForAutoLayout(Icon(with: #imageLiteral(resourceName: "checkbox_checked_pdf"))))
        }
        
        return icons
    }()
    
    private lazy var bulletpointLabels: [Label] =
    {
        var labels = [Label]()
        
        for bulletpoint in bulletpoints
        {
            let label = addForAutoLayout(Label())
            label.font = Font.purchasePanel.nsFont
            label.stringValue = bulletpoint
            label.lineBreakMode = .byWordWrapping
            labels.append(label)
        }
        
        return labels
    }()
    
    private let bulletpoints =
    [
        "Infinite items, no more trial version info bar",
        "Pay once, use it forever - no subscription",
        "Support the development of more features",
        "Users vote on which features come next. The link is in the Help menu.",
        "Early bird advantage: Get new features as free updates, even when the full version price rises"
    ]
}
