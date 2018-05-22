import AppKit

class TextField: NSTextField
{
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
