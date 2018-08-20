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
        isRichText = true
        
        delegate = self
        
        defaultParagraphStyle = TextView.paragraphStyle
        typingAttributes = TextView.typingSyle
        selectedTextAttributes = TextView.selectionSyle
        linkTextAttributes = TextView.linkStyle
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Layout Dependent On Line Height
    
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
    
    static var itemHeight: CGFloat
    {
        return 2 * itemPadding + lineHeight
    }
    
    static var itemSpacing: CGFloat { return itemLineSpacing }
    
    static var itemLineSpacing: CGFloat
    {
        return 2 * itemPadding - lineHeight
    }
    
    static var itemPadding: CGFloat
    {
        return CGFloat(Int(lineHeight * 0.647 + 0.5))
    }

    // MARK: - Measuring Size
    
    static var lineHeight: CGFloat
    {
        return measuringLayoutManager.defaultLineHeight(for: Font.text.nsFont)
    }
    
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
    
    private static var typingSyle: [NSAttributedStringKey : Any]
    {
        return [.font : Font.text.nsFont,
                .paragraphStyle : TextView.paragraphStyle]
    }
    
    private static let selectionSyle: [NSAttributedStringKey : Any] =
    [
        .backgroundColor : Color.gray(brightness: 0.9).nsColor
    ]
    
    private static let linkStyle: [NSAttributedStringKey : Any] =
    [
        NSAttributedStringKey.underlineStyle : NSUnderlineStyle.styleSingle.rawValue
    ]
    
    private static var fieldFont: NSFont
    {
        return Font.text.nsFont
    }
    
    private static var paragraphStyle: NSParagraphStyle
    {
        let style = NSMutableParagraphStyle()
        
        style.lineSpacing = TextView.itemLineSpacing
        
        return style
    }
    
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
        guard NSApp.mainWindow?.makeFirstResponder(self) ?? false else { return }
        
        setSelectedRange(NSMakeRange(string.count, 0))
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
        TextView.isEditing = false

        messenger.send(.didEdit)
    }
    
    private func willEdit()
    {
        TextView.isEditing = true
        
        messenger.send(.willEdit)
    }

    static var isEditing = false
    
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
