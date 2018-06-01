import AppKit

class GroupIcon: NSImageView
{
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        image = #imageLiteral(resourceName: "group_indicator")
        imageScaling = .scaleNone
        imageAlignment = .alignCenter
    }
    
    required init?(coder: NSCoder) { fatalError() }
}
