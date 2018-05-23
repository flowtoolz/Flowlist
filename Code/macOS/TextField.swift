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
        isEditable = true
        font = Font.text.nsFont
        lineBreakMode = .byTruncatingTail
    }
    
    required init?(coder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Observability
    
    override func becomeFirstResponder() -> Bool
    {
        let didBecomeFirstResponder = super.becomeFirstResponder()
        
        if didBecomeFirstResponder { send(.didGainFocus) }
        
        return didBecomeFirstResponder
    }
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event { case didNothing, didGainFocus }
}
