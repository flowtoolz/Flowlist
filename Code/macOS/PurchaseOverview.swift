import AppKit.NSView
import UIToolz

class PurchaseOverview: NSView
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
            
            let label = bulletpointLabels[index]
            //label.autoPinEdge(.left, to: .right, of: icon, withOffset: 10)
            label.autoPinEdge(toSuperviewEdge: .right)
            label.autoPinEdge(toSuperviewEdge: .left, withInset: 25)
            
            if index == 0
            {
                label.autoPinEdge(toSuperviewEdge: .top)
            }
            
            if index == bulletpoints.count - 1
            {
                label.autoPinEdge(toSuperviewEdge: .bottom)
            }
            
            if index > 0
            {
                label.autoPinEdge(.top,
                                  to: .bottom,
                                  of: bulletpointLabels[index - 1],
                                  withOffset: 10)
            }
            
            icon.autoConstrainAttribute(.top, to: .top, of: label)
        }
    }
    
    private lazy var bulletpointIcons: [Icon] =
    {
        var icons = [Icon]()
        
        for _ in bulletpoints
        {
            icons.append(addForAutoLayout(Icon(with: #imageLiteral(resourceName: "checkbox_checked"))))
        }
        
        return icons
    }()
    
    private lazy var bulletpointLabels: [Label] =
    {
        var labels = [Label]()
        
        for bulletpoint in bulletpoints
        {
            let label = addForAutoLayout(Label())
            label.stringValue = bulletpoint
            label.lineBreakMode = .byWordWrapping
            labels.append(label)
        }
        
        return labels
    }()
    
    private let bulletpoints =
    [
        "Infinite items. The info bar at the bottom of the window will be gone.",
        "Pay once, then use the full version forever, no subscription required.",
        "Support the development of Flowlist and enable me to add more features.",
        "Early bird advantage: Users who have the full version get new features as free updates, even when the full version price will increase."
    ]
}
