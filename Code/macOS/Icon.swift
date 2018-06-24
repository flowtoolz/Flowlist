import AppKit

class Icon: NSImageView
{
    init(with image: NSImage)
    {
        super.init(frame: .zero)
        
        self.image = image
        imageScaling = .scaleNone
        imageAlignment = .alignCenter
    }
    
    required init?(coder: NSCoder) { fatalError() }
}
