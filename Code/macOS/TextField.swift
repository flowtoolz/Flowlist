import AppKit
import SwiftObserver
import SwiftyToolz

class TextField: Label, Observable
{
    // MARK: - Initialization

    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        drawsBackground = false
        isEditable = true
        font = TextField.fieldFont
        focusRingType = .none
        lineBreakMode = .byWordWrapping
        
        if #available(OSX 10.11, *)
        {
            allowsDefaultTighteningForTruncation = true
            maximumNumberOfLines = 0
        }
        
        set(placeholder: "untitled")
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Sizing
    
    static let heightOfOneLine = intrinsicSize(with: "a",
                                               width: CGFloat.greatestFiniteMagnitude).height
    
    static func intrinsicSize(with text: String, width: CGFloat) -> CGSize
    {
        measuringCell.stringValue = text
        
        let textBounds = CGRect(x: 0,
                                y: 0,
                                width: width,
                                height: CGFloat.greatestFiniteMagnitude)
        
        return measuringCell.cellSize(forBounds: textBounds)
    }
    
    private static let measuringCell: NSCell =
    {
        let cell = NSCell(textCell: "")
        
        cell.font = TextField.fieldFont
        cell.focusRingType = .none
        cell.lineBreakMode = .byWordWrapping
        
        return cell
    }()
    
    private static let fieldFont = Font.text.nsFont
    
    // MARK: - Setup Placeholder
    
    private func set(placeholder: String)
    {
        let attributes: [NSAttributedStringKey : Any] =
        [
            .foregroundColor: Color.grayedOut.nsColor,
            .font: TextField.fieldFont
        ]
        
        let attributedString = NSAttributedString(string: placeholder,
                                                  attributes: attributes)
        
        placeholderAttributedString = attributedString
    }
    
    // MARK: - Update
    
    func update(with state: TaskState?)
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
    
    func startEditing()
    {
        guard stringValue != "" else
        {
            selectText(self)
            return
        }
        
        guard let fieldEditor = NSApp.mainWindow?.fieldEditor(true, for: nil) else
        {
            return
        }
        
        select(withFrame: bounds,
               editor: fieldEditor,
               delegate: self,
               start: stringValue.count,
               length:0)
        
        willEdit()
    }
    
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
