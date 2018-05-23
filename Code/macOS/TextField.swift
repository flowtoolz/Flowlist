import AppKit
import SwiftObserver
import SwiftyToolz

class TextField: NSTextField, Observable
{
    // MARK: - Initialization
    
    convenience init(_ placeholder: String)
    {
        self.init(frame: .zero)
        
        translatesAutoresizingMaskIntoConstraints = false
        
        let attributes: [NSAttributedStringKey : Any] =
        [
            NSAttributedStringKey.foregroundColor: Color.grayedOut.nsColor,
            NSAttributedStringKey.font: Font.text.nsFont
        ]
        
        let attributedString = NSAttributedString(string: placeholder,
                                                  attributes: attributes)
        
        placeholderAttributedString = attributedString
    }
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        isBordered = false
        drawsBackground = false
        isBezeled = false
        lineBreakMode = .byTruncatingTail
        font = Font.text.nsFont
    }
    
    required init?(coder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Observability
    
    override func becomeFirstResponder() -> Bool
    {
        let isFirstResponder = super.becomeFirstResponder()
        
        if isFirstResponder { send(.didBecomeFirstResponder) }
        
        return isFirstResponder
    }
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event { case didNothing, didBecomeFirstResponder }
}
