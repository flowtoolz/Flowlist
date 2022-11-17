import AppKit
import SwiftObserver
import SwiftyToolz

class TextView: NSTextView, NSTextViewDelegate, SwiftObserver.Observable
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
        textContainer?.lineFragmentPadding = TextView.lineFragmentPadding
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
    
    required init?(coder: NSCoder) { nil }
    
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
    
    private static var typingSyle: [NSAttributedString.Key : Any]
    {
        [
            .font : Font.text.nsFont,
            .paragraphStyle : TextView.paragraphStyle
        ]
    }
    
    static var selectionSyle: [NSAttributedString.Key : Any]
    {
        [.backgroundColor : Color.textSelectedBackground.nsColor]
    }
    
    private static let linkStyle: [NSAttributedString.Key : Any] =
    [
        .underlineStyle : NSUnderlineStyle.single.rawValue
    ]
    
    private static var textFont: NSFont
    {
        Font.text.nsFont
    }
    
    private static var paragraphStyle: NSParagraphStyle
    {
        let style = NSMutableParagraphStyle()
        
        style.lineSpacing = TextView.lineSpacing
        
        return style
    }
    
    static var lineSpacing: Double
    {
        .lineSpacing(for: TextView.lineHeight)
    }
    
    // MARK: - Measure Height
    
    static var lineHeight: CGFloat
    {
        let fontSize = Font.baseSize.value
        
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
        
        container.lineFragmentPadding = TextView.lineFragmentPadding
        
        return container
    }()
    
    private static let lineFragmentPadding: CGFloat = 1
    
    // MARK: - Update

    override var string: String
    {
        didSet
        {
            checkTextInDocument(nil)
        }
    }
    
    // MARK: - Editing
    
    @discardableResult
    func startEditing() -> Bool
    {
        guard window != nil else
        {
            log(error: "TextView is not in window hierarchy. Forgot to stop ItemData observation?")
            return false
        }
        
        guard NSApp.mainWindow?.makeFirstResponder(self) ?? false else
        {
            log(error: "Could not become first responder.")
            return false
        }
        
        setSelectedRange(NSMakeRange(string.count, 0))
        
        return true
    }
    
    override var acceptsFirstResponder: Bool { true }

    override func becomeFirstResponder() -> Bool
    {
        let willBecomeFirstResponder = super.becomeFirstResponder()
        
        if willBecomeFirstResponder { willEdit() }
        
        return willBecomeFirstResponder
    }
    
    override func resignFirstResponder() -> Bool
    {
        let willResignFirstResponder = super.resignFirstResponder()
        
        if willResignFirstResponder && isEditing { didEdit() }
        
        return willResignFirstResponder
    }
    
    override func shouldChangeText(in affectedCharRange: NSRange,
                                   replacementString: String?) -> Bool
    {
        guard replacementString != " " || string != "" else { return false }
        
        guard replacementString != "\n" else
        {
            send(.wantToEndEditing)
            return false
        }
        
        return super.shouldChangeText(in: affectedCharRange,
                                      replacementString: replacementString)
    }
    
    override func cancelOperation(_ sender: Any?)
    {
        send(.wantToEndEditing)
    }
    
    func textDidChange(_ notification: Notification)
    {
        send(.didChangeText)
    }

    func textDidEndEditing(_ notification: Notification)
    {
        checkTextInDocument(nil)
        setSelectedRange(NSMakeRange(string.count, 0))
    }
    
    private func didEdit()
    {
        isEditing = false
        TextView.isEditing <- false
        isEditable = false

        send(.didEdit)
    }
    
    private func willEdit()
    {
        isEditing = true
        TextView.isEditing <- true
        isEditable = true
        
        send(.willEdit)
    }
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool
    {
        guard isEditing, event.cmd, let characters = event.characters else
        {
            return false
        }
        
        switch characters
        {
        case "v": pasteAsPlainText(nil)
        case "c": copy(nil)
        case "x": cut(nil)
        case "a": selectAll(nil)
        default: return false
        }
        
        return true
    }
    
    private(set) var isEditing = false

    static let isEditing = Var(false)
    
    // MARK: - Inform Item View that Text was Clicked
    
    override func mouseDown(with event: NSEvent)
    {
        super.mouseDown(with: event)
        
        send(.wasClicked)
    }
    
    // MARK: - Observability
    
    let messenger = Messenger<Event>()
    
    enum Event
    {
        case wasClicked
        case willEdit
        case didChangeText
        case wantToEndEditing
        case didEdit
    }
}
