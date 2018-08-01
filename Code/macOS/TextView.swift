import AppKit
import SwiftObserver
import SwiftyToolz

class TextView: NSTextView, Observable, NSTextViewDelegate
{
    // MARK: - Initialization

    init()
    {
        super.init(frame: NSZeroRect)
        
        isSelectable = true
        isEditable = true
        focusRingType = .none
        drawsBackground = false
        textContainerInset = CGSize.zero
        textContainer?.lineFragmentPadding = 0
        isAutomaticLinkDetectionEnabled = true
        isRichText = true
        
        delegate = self
        
        font = TextView.fieldFont
        defaultParagraphStyle = TextView.paragraphStyle
        selectedTextAttributes = TextView.selectionSyle
        typingAttributes = TextView.typingStyle
        linkTextAttributes = TextView.linkStyle
        
        set(placeholder: "untitled")
    }
    
    // needed to avoid crash. seems it's implicitly required, and a bug.
    private override init(frame frameRect: NSRect,
                  textContainer container: NSTextContainer?)
    {
        super.init(frame: frameRect, textContainer: container)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Placeholder
    
    private func set(placeholder: String)
    {
        let attributes: [NSAttributedStringKey : Any] =
        [
            .foregroundColor: Color.grayedOut.nsColor,
            .font: TextView.fieldFont
        ]
        
        let attributedString = NSAttributedString(string: placeholder,
                                                  attributes: attributes)
        
        placeholderAttributedString = attributedString
    }
    
    @objc var placeholderAttributedString: NSAttributedString?
    
    // MARK: - Measuring Size
    
    static let heightOfOneLine = size(with: "a",
                                      width: CGFloat.greatestFiniteMagnitude).height
    
    static func size(with text: String, width: CGFloat) -> CGSize
    {
        measuringTextContainer.containerSize.width = width
        
        let textStorage = NSTextStorage(string: text)
        
        textStorage.addLayoutManager(measuringLayoutManager)
        
        let range = NSMakeRange(0, textStorage.length)
        
        textStorage.addAttribute(.font,
                                 value: TextView.fieldFont,
                                 range: range)
        
        textStorage.addAttribute(.paragraphStyle,
                                 value: TextView.paragraphStyle,
                                 range: range)
        
        _ = measuringLayoutManager.glyphRange(for: measuringTextContainer)
        
        return measuringLayoutManager.usedRect(for: measuringTextContainer).size
    }
    
    private static let measuringLayoutManager: NSLayoutManager =
    {
        let manager = NSLayoutManager()
        
        manager.addTextContainer(measuringTextContainer)
        
        return manager
    }()
    
    private static let measuringTextContainer: NSTextContainer =
    {
        let size = NSMakeSize(0, CGFloat.greatestFiniteMagnitude)
        
        let container = NSTextContainer(containerSize: size)
        
        container.lineFragmentPadding = 0
        
        return container
    }()

    // MARK: - Style
    
    private static let selectionSyle: [NSAttributedStringKey : Any] =
    [
        .backgroundColor : Color.flowlistBlueVeryTransparent.nsColor
    ]
    
    private static let typingStyle: [NSAttributedStringKey : Any] =
    [
        .paragraphStyle : TextView.paragraphStyle,
        .font : TextView.fieldFont
    ]
    
    private static let linkStyle: [NSAttributedStringKey : Any] =
    [
        .paragraphStyle : TextView.paragraphStyle,
        .font : TextView.fieldFont,
        .foregroundColor: NSColor.red
    ]
    
    private static let fieldFont = Font.text.nsFont
    
    private static let paragraphStyle: NSParagraphStyle =
    {
        let style = NSMutableParagraphStyle()
        
        style.lineSpacing = TextView.lineSpacing
        
        return style
    }()
    
    static let lineSpacing: CGFloat = 5.0
    
    // MARK: - Update
    
    func update(with state: TaskState?)
    {
        let color: Color = state == .done ? .grayedOut : .black
        textColor = color.nsColor
    }
    
    // MARK: - Avoid Beep When Return is Dispatched While Some Field Is Editing
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool
    {
        if event.key == .enter && TextView.isEditing { return true }
        
        return super.performKeyEquivalent(with: event)
    }
    
    // MARK: - Editing
    
    func startEditing()
    {
        guard NSApp.mainWindow?.makeFirstResponder(self) ?? false else { return }
        
        setSelectedRange(NSMakeRange(string.count, 0))
    }

    override func becomeFirstResponder() -> Bool
    {
        let willBecomeFirstResponder = super.becomeFirstResponder()
        
        if willBecomeFirstResponder { willEdit() }
        
        return willBecomeFirstResponder
    }
    
    override func shouldChangeText(in affectedCharRange: NSRange,
                                   replacementString: String?) -> Bool
    {
        guard replacementString != "\n" else
        {
            send(.wantToEndEditing)
            return false
        }
        
        return super.shouldChangeText(in: affectedCharRange,
                                      replacementString: replacementString)
    }
    
    func textDidChange(_ notification: Notification)
    {
        send(.didChange(text: string))
    }

    func textDidEndEditing(_ notification: Notification)
    {
        setSelectedRange(NSMakeRange(string.count, 0))
        didEdit()
    }
    
    private func didEdit()
    {
        TextView.isEditing = false

        send(.didEdit)
    }
    
    private func willEdit()
    {
        TextView.isEditing = true
        
        send(.willEdit)
    }

    static var isEditing = false
    
    // MARK: - Observability
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event
    {
        case didNothing, willEdit, didChange(text: String), wantToEndEditing, didEdit
    }
}
