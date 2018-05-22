import AppKit
import SwiftyToolz

class TextField: NSTextField
{
    // MARK: - Initialization
    
    convenience init(_ placeholder: String)
    {
        self.init(frame: .zero)
        
        translatesAutoresizingMaskIntoConstraints = false
        
        let attributes: [NSAttributedStringKey : Any] =
        [
            NSAttributedStringKey.foregroundColor: Color.grayedOut.nsColor,
            NSAttributedStringKey.font: NSFont.systemFont(ofSize: 13)
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
        font = NSFont.systemFont(ofSize: 13)
        lineBreakMode = .byTruncatingTail
    }
    
    required init?(coder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - TextFieldDelegate
    
    override func becomeFirstResponder() -> Bool
    {
        let didBecomeFirstResponder = super.becomeFirstResponder()
        
        if didBecomeFirstResponder
        {
            textFieldDelegate?.textFieldDidBecomeFirstResponder(self)
        }
        
        return didBecomeFirstResponder
    }
    
    weak var textFieldDelegate: TextFieldDelegate?
}

protocol TextFieldDelegate: AnyObject
{
    func textFieldDidBecomeFirstResponder(_ textField: TextField)
}
