import AppKit.NSTextField

class Label: NSTextField
{
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        let priority = NSLayoutConstraint.Priority(rawValue: 0.1)
        setContentCompressionResistancePriority(priority, for: .horizontal)
        lineBreakMode = .byTruncatingTail
        
        if #available(OSX 10.11, *)
        {
            allowsDefaultTighteningForTruncation = true
        }
        
        drawsBackground = false

        isBezeled = false
        isEditable = false
        isBordered = false
    }
    
    required init?(coder: NSCoder) { fatalError() }
}
