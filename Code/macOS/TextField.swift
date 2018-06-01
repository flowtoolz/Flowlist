import AppKit
import SwiftObserver
import SwiftyToolz

class TextField: NSTextField, Observable
{
    // MARK: - Initialization

    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        isBordered = false
        drawsBackground = false
        isBezeled = false
        lineBreakMode = .byTruncatingTail
        font = Font.text.nsFont
        
        set(placeholder: "untitled")
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Setup Placeholder
    
    private func set(placeholder: String)
    {
        let attributes: [NSAttributedStringKey : Any] =
            [
                NSAttributedStringKey.foregroundColor: Color.grayedOut.nsColor,
                NSAttributedStringKey.font: Font.text.nsFont
        ]
        
        let attributedString = NSAttributedString(string: placeholder,
                                                  attributes: attributes)
        
        placeholderAttributedString = attributedString
    }
    
    // MARK: - Update
    
    func update(with state: Task.State?)
    {
        let color: Color = state == .done ? .grayedOut : .black
        textColor = color.nsColor
    }
    
    // MARK: - Avoid Beep When Return is Dispatched While Some Field Is Editing
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool
    {
        if event.key == .enter && TextField.isEditing { return true }
        
        return super.performKeyEquivalent(with: event)
    }

    // MARK: - Editing State
    
    override func selectText(_ sender: Any?)
    {
        willEdit()
        
        super.selectText(sender)
    }
    
    override func textDidChange(_ notification: Notification)
    {
        super.textDidChange(notification)
        
        send(.didChange(text: stringValue))
    }
    
    override func abortEditing() -> Bool
    {
        let abort = super.abortEditing()
        
        if abort { didEdit() }

        return abort
    }
    
    override func textDidEndEditing(_ notification: Notification)
    {
        super.textDidEndEditing(notification)

        didEdit()
    }
    
    private func didEdit()
    {
        TextField.isEditing = false

        send(.didEdit)
    }
    
    private func willEdit()
    {
        TextField.isEditing = true
        
        send(.willEdit)
    }

    static var isEditing = false
    
    // MARK: - Observability
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event { case didNothing, willEdit, didChange(text: String), didEdit }
}
