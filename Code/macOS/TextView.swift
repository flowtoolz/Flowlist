import AppKit
import SwiftObserver
import SwiftyToolz

class TextView: NSTextView, NSTextViewDelegate
{
    // MARK: - Life Cycle

    convenience init()
    {
        self.init(frame: NSZeroRect)
    }
    
    private override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
    }
    
    private override init(frame frameRect: NSRect,
                          textContainer container: NSTextContainer?)
    {
        super.init(frame: frameRect, textContainer: container)
        
        isSelectable = true
        isEditable = true
        focusRingType = .none
        drawsBackground = false
        textContainerInset = .zero
        textContainer?.lineFragmentPadding = 0
        isAutomaticLinkDetectionEnabled = true
        isAutomaticDataDetectionEnabled = true
        isRichText = false
        
        let lowestPriority = NSLayoutConstraint.Priority(rawValue: 0.1)
        setContentHuggingPriority(lowestPriority, for: .vertical)
        setContentHuggingPriority(lowestPriority, for: .horizontal)
        
        delegate = self
        
        defaultParagraphStyle = TextView.paragraphStyle
        typingAttributes = TextView.typingSyle
        selectedTextAttributes = TextView.selectionSyle
        linkTextAttributes = TextView.linkStyle
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Adapt to Font Size
    
    func fontSizeDidChange()
    {
        let paragraphStyle = TextView.paragraphStyle
        
        defaultParagraphStyle = paragraphStyle

        typingAttributes = TextView.typingSyle

        textStorage?.font = Font.text.nsFont
        
        let range = NSRange(location: 0, length: textStorage?.length ?? 0)
        textStorage?.addAttribute(.paragraphStyle,
                                  value: paragraphStyle,
                                  range: range)
    }
    
    // MARK: - Style
    
    func set(color: Color)
    {
        self.textColor = color.nsColor
    }
    
    private static var typingSyle: [NSAttributedStringKey : Any]
    {
        return [.font : Font.text.nsFont,
                .paragraphStyle : TextView.paragraphStyle]
    }
    
    static var selectionSyle: [NSAttributedStringKey : Any]
    {
        return [.backgroundColor : Color.textSelectedBackground.nsColor]
    }
    
    private static let linkStyle: [NSAttributedStringKey : Any] =
    [
        .underlineStyle : NSUnderlineStyle.styleSingle.rawValue
    ]
    
    private static var textFont: NSFont
    {
        return Font.text.nsFont
    }
    
    private static var paragraphStyle: NSParagraphStyle
    {
        let style = NSMutableParagraphStyle()
        
        style.lineSpacing = TextView.lineSpacing
        
        return style
    }
    
    static var lineSpacing: CGFloat
    {
        return Float.lineSpacing(for: Float(TextView.lineHeight)).cgFloat
    }
    
    // MARK: - Measure Height
    
    static var lineHeight: CGFloat
    {
        let fontSize = Font.baseSize.latestUpdate
        
        if let height = lineHeightCash[fontSize]
        {
            return height
        }
        else
        {
            let height = measuringLayoutManager.defaultLineHeight(for: Font.text.nsFont)
            
            lineHeightCash[fontSize] = height
            
            return height
        }
    }
    
    private static var lineHeightCash = [Int : CGFloat]()
    
    static func size(with text: String, width: CGFloat) -> CGSize
    {
        measuringTextContainer.containerSize.width = width
        
        let textStorage = NSTextStorage(string: text)
        
        textStorage.addLayoutManager(measuringLayoutManager)
        
        let range = NSMakeRange(0, textStorage.length)
        
        textStorage.addAttribute(.font,
                                 value: TextView.textFont,
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
    
    // MARK: - Update

    override var string: String
    {
        didSet
        {
            checkTextInDocument(nil)
        }
    }
    
    // MARK: - Editing
    
    func startEditing()
    {
        guard window != nil else
        {
            log(error: "TextView is not in window hierarchy. Forgot to stop ItemData observation?")
            return
        }
        
        guard NSApp.mainWindow?.makeFirstResponder(self) ?? false else
        {
            log(error: "Could not become first responder.")
            return
        }
        
        setSelectedRange(NSMakeRange(string.count, 0))
    }
    
    override var acceptsFirstResponder: Bool
    {
        return true
    }

    override func becomeFirstResponder() -> Bool
    {
        let willBecomeFirstResponder = super.becomeFirstResponder()
        
        if willBecomeFirstResponder { willEdit() }
        
        return willBecomeFirstResponder
    }
    
    override func resignFirstResponder() -> Bool
    {
        let willResignFirstResponder = super.resignFirstResponder()
        
        if willResignFirstResponder { didEdit() }
        
        return willResignFirstResponder
    }
    
    override func shouldChangeText(in affectedCharRange: NSRange,
                                   replacementString: String?) -> Bool
    {
        guard replacementString != " " || string != "" else { return false }
        
        guard replacementString != "\n" else
        {
            messenger.send(.wantToEndEditing)
            return false
        }
        
        return super.shouldChangeText(in: affectedCharRange,
                                      replacementString: replacementString)
    }
    
    func textDidChange(_ notification: Notification)
    {
        messenger.send(.didChange(text: string))
    }

    func textDidEndEditing(_ notification: Notification)
    {
        checkTextInDocument(nil)
        setSelectedRange(NSMakeRange(string.count, 0))
    }
    
    private func didEdit()
    {
        isEditing = false
        TextView.isEditing = false
        isEditable = false

        messenger.send(.didEdit)
    }
    
    private func willEdit()
    {
        isEditing = true
        TextView.isEditing = true
        isEditable = true
        
        messenger.send(.willEdit)
    }
    
    private(set) var isEditing = false

    static var isEditing = false
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool
    {
        guard NSApp.mainWindow?.firstResponder === self,
            event.cmd,
            let characters = event.characters
            else
        {
            return super.performKeyEquivalent(with: event)
        }
        
        switch characters
        {
        case "v": pasteAsPlainText(nil)
        case "c": copy(nil)
        case "x": cut(nil)
        case "a": selectAll(nil)
        default: return super.performKeyEquivalent(with: event)
        }
        
        return true
    }
    
    // MARK: - Observability
    
    let messenger = Messenger()
    
    class Messenger: Observable
    {
        var latestUpdate: Event { return .didNothing }
        
        enum Event
        {
            case didNothing
            case willEdit
            case didChange(text: String)
            case wantToEndEditing
            case didEdit
        }
    }
}
