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
    
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Update
    
    func update(with state: Task.State?)
    {
        let color: Color = state == .done ? .grayedOut : .black
        textColor = color.nsColor
    }

    // MARK: - Observability
    
    override func becomeFirstResponder() -> Bool
    {
        let willBeFirstResponder = super.becomeFirstResponder()
        
        if willBeFirstResponder { send(.willBecomeFirstResponder) }
        
        return willBeFirstResponder
    }
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event { case didNothing, willBecomeFirstResponder }
}
