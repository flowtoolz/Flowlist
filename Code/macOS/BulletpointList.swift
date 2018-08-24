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
            icon.autoPinEdge(toSuperviewEdge: .left)
            icon.autoSetDimensions(to: CGSize(width: defaultIconSize,
                                              height: defaultIconSize))
            
            let label = bulletpointLabels[index]
            label.autoPinEdge(toSuperviewEdge: .right)
            label.autoPinEdge(toSuperviewEdge: .left, withInset: 27)
            
            if index == 0
            {
                label.autoPinEdge(toSuperviewEdge: .top)
            }
            
            if index == bulletpoints.count - 1
            {
                label.autoPinEdge(toSuperviewEdge: .bottom, withInset: 10)
            }
            
            if index > 0
            {
                label.autoPinEdge(.top,
                                  to: .bottom,
                                  of: bulletpointLabels[index - 1],
                                  withOffset: 20)
            }
            
            icon.autoConstrainAttribute(.top, to: .top, of: label)
        }
    }
    
    private let defaultIconSize = TextView.lineHeight
    
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
            label.font = Font.text.nsFont
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
        "Users vote on which features come next",
        "Early bird advantage: Get new features as free updates, even when the full version price rises"
    ]
}
