import AppKit
import UIToolz
import SwiftObserver
import SwiftyToolz
import GetLaid

class TaskView: LayerBackedView, Observer, Observable
{
    // MARK: - Life Cycle
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        identifier = TaskView.uiIdentifier
        
        constrainColorOverlay()
        constrainLayoutGuide()
        constrainEditingBackground()
        constrainCheckBox()
        contrainGroupIcon()
        constrainTextView()
        
        layer?.borderWidth = 1.0
        layer?.cornerRadius = Float.cornerRadius.cgFloat
        
        observe(TextView.lineHeightVariable)
        {
            [weak self] _ in self?.fontSizeDidChange()
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    deinit
    {
        stopAllObserving()
        removeObservers()
    }
    
    // MARK: - Adapt to Font Size Changes
    
    private func fontSizeDidChange()
    {
        let itemHeight = TaskView.heightWithSingleLine
        
        layoutGuideHeightConstraint?.constant = itemHeight
        layoutGuideWidthConstraint?.constant = itemHeight
        
        textView.fontSizeDidChange()
    }
    
    // MARK: - Configuration
    
    func configure(with task: Task?) -> TaskView?
    {
        guard let task = task else
        {
            log(error: "Cannot configure \(typeName(self)) with nil task.")
            return nil
        }
        
        stopObserving(task: self.task)
        observe(task: task)
        self.task = task
        
        isSelected = false
        
        let state = task.state.value
        
        updateColors(with: state)
        checkBox.configure(with: state, whiteColorMode: isSelected)
        updateTextView()
        updateGroupIcon()
        
        return self
    }
    
    private func observe(task: Task)
    {
        observe(task)
        {
            [weak self, weak task] event in
            
            guard let task = task else { return }
            
            self?.received(event, from: task)
        }
        
        observe(task.state)
        {
            [weak self] _ in self?.taskStateDidChange()
        }
        
        observe(task.tag)
        {
            [weak self] _ in self?.updateColors(with: self?.task?.state.value)
        }
    }
    
    private func received(_ event: Task.Event, from task: Task)
    {
        switch event
        {
        case .didNothing: break
        case .didChange(numberOfLeafs: _): break
        case .did(let edit): if edit.changesItems { updateGroupIcon() }
        }
    }
    
    private func stopObserving(task: Task?)
    {
        stopObserving(task?.state)
        stopObserving(task?.title)
        stopObserving(task)
    }
    
    // MARK: - Task State & Colors
    
    private func taskStateDidChange()
    {
        let state = task?.state.value
        
        updateColors(with: state)
        checkBox.update(with: state)
    }
    
    private func updateColors(with state: TaskState?)
    {
        guard let task = task else { return }
        
        if task.isDone
        {
            colorOverlay.backgroundColor = Color.gray(brightness: 0.6)
            colorOverlay.isHidden = false
            
            layer?.borderColor = Color.border.cgColor
            
            alphaValue = 0.5
        }
        else if let tag = task.tag.value
        {
            let tagColor = Color.tags[tag.rawValue]
            
            colorOverlay.backgroundColor = tagColor
            colorOverlay.isHidden = false
            
            layer?.borderColor = tagColor.with(alpha: 0.5).cgColor
            
            alphaValue = 1
        }
        else
        {
            colorOverlay.isHidden = true
            
            layer?.borderColor = Color.border.cgColor
            
            alphaValue = 1
        }
    }
    
    // MARK: - Selection
    
    override func mouseDown(with event: NSEvent)
    {
        send(.wasClicked(withCmd: event.cmd))
    }
    
    var isSelected = false
    {
        didSet
        {
            backgroundColor = isSelected ? .selection : .white
            
            if !textView.isEditing
            {
                textView.set(textColor: isSelected ? .white : .black)
            }
            
            groupIcon.image = isSelected ? TaskView.groupIconImageWhite : TaskView.groupIconImage
            checkBox.setColorMode(white: isSelected)
        }
    }
    
    // MARK: - Color Overlay
    
    private func constrainColorOverlay()
    {
        colorOverlay.constrain(to: self)
    }
    
    private lazy var colorOverlay: LayerBackedView =
    {
        let view = addForAutoLayout(LayerBackedView())
        
        view.alphaValue = Float.colorOverlayAlpha.cgFloat
        
        return view
    }()
    
    // MARK: - Text View
    
    func editText()
    {
        textView.startEditing()
    }
    
    private func updateTextView()
    {
        // https://stackoverflow.com/questions/19121367/uitextviews-in-a-uitableview-link-detection-bug-in-ios-7
        textView.string = ""
        textView.string = task?.title.value ?? ""
    }
    
    private func constrainTextView()
    {
        textView.constrainLeft(to: TaskView.textLeftMultiplier, of: layoutGuide)
        textView.constrain(toTheLeftOf: groupIcon)
        textView.constrainTop(to: checkBox)
        textView.constrainBottomToParent()
    }
    
    private static let textLeftMultiplier: CGFloat = 0.9
    
    private lazy var textView: TextView =
    {
        let view = addForAutoLayout(TextView())
        
        self.observe(view.messenger) { [weak self] in self?.didReceive($0) }
        
        return view
    }()
    
    private func didReceive(_ event: TextView.Messenger.Event)
    {
        switch event
        {
        case .didNothing: break
            
        case .willEdit:
            set(editing: true)
            task?.isBeingEdited = true
            send(.willEditTitle)
            
        case .didChange(let text):
            send(.didChangeTitle)
            task?.title <- String(withNonEmpty: text)
            
        case .wantToEndEditing:
            send(.wantToEndEditingText)
            
        case .didEdit:
            set(editing: false)
            task?.title <- String(withNonEmpty: textView.string)
            task?.isBeingEdited = false
            send(.didEditTitle)
        }
    }
    
    private func set(editing: Bool)
    {
        textView.textColor = editing ? .black : .white
        editingBackground.alphaValue = editing ? 1 : 0
        
        if !editing
        {
            checkBox.isEnabled = true
        }
        
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.allowsImplicitAnimation = false
        NSAnimationContext.current.duration = 0.2
        NSAnimationContext.current.completionHandler =
            {
                if editing
                {
                    self.checkBox.isEnabled = false
                }
        }
        
        groupIcon.animator().alphaValue = editing ? 0 : 1
        checkBox.animator().alphaValue = editing ? 0 : 1
        
        NSAnimationContext.endGrouping()
    }
    
    // MARK: - Editing Background
    
    private func constrainEditingBackground()
    {
        let insets = Insets(top: 5, left: 20, bottom: 5, right: 20)
        editingBackground.constrainToParent(insets: insets)
    }
    
    private lazy var editingBackground: LayerBackedView =
    {
        let view = addForAutoLayout(LayerBackedView())
        
        view.backgroundColor = .white
        view.alphaValue = 0
        view.layer?.cornerRadius = Float.cornerRadius.cgFloat
        
        return view
    }()
    
    // MARK: - Check Box
    
    private func constrainCheckBox()
    {
        checkBox.constrainSize(to: 0.45, 0.45, of: layoutGuide)
        checkBox.constrainCenter(to: layoutGuide)
    }
    
    private lazy var checkBox: CheckBox =
    {
        let box = addForAutoLayout(CheckBox())
        
        box.action = #selector(didClickCheckBox)
        box.target = self
        
        return box
    }()
    
    @objc private func didClickCheckBox()
    {
        task?.state <- task?.isDone ?? false ? nil : .done
    }
    
    // MARK: - Group Icon
    
    private func updateGroupIcon()
    {
        groupIcon.isHidden = !(task?.hasBranches ?? false)
    }
    
    private func contrainGroupIcon()
    {
        groupIcon.constrainRightToParent()
        groupIcon.constrainCenterY(to: layoutGuide)
        groupIcon.constrainHeight(to: checkBox)
        groupIcon.constrainWidth(to: TaskView.groupIconWidthMultiplier, of: layoutGuide)
    }
    
    private static let groupIconWidthMultiplier: CGFloat = 0.75
    
    private lazy var groupIcon = addForAutoLayout(Icon(with: TaskView.groupIconImage))
    
    private static let groupIconImage = #imageLiteral(resourceName: "container_indicator_pdf")
    private static let groupIconImageWhite = #imageLiteral(resourceName: "container_indicator_white")
    
    // MARK: - Layout Guide
    
    private func constrainLayoutGuide()
    {
        layoutGuide.constrainLeft(to: self)
        layoutGuide.constrainTop(to: self)
        
        let size = TaskView.heightWithSingleLine
        
        layoutGuideHeightConstraint = layoutGuide.constrainHeight(to: size)
        layoutGuideWidthConstraint = layoutGuide.constrainWidth(to: size)
    }
    
    private var layoutGuideHeightConstraint: NSLayoutConstraint?
    private var layoutGuideWidthConstraint: NSLayoutConstraint?
    
    private lazy var layoutGuide = addLayoutGuide()
    
    // MARK: - Measuring Size
    
    static func preferredHeight(for text: String, width: CGFloat) -> CGFloat
    {
        let pixelsPerPoint = NSApp.mainWindow?.backingScaleFactor ?? 2
        
        let referenceHeight = heightWithSingleLine * pixelsPerPoint
        
        let leftInset  = CGFloat(Int(referenceHeight * textLeftMultiplier + 0.5))
        
        let rightInset = CGFloat(Int(referenceHeight * groupIconWidthMultiplier + 0.49999))
        
        let textWidth = ((pixelsPerPoint * width) - (leftInset + rightInset)) / pixelsPerPoint
        
        let textHeight = TextView.size(with: text, width: textWidth).height
        
        return textHeight + (2 * padding)
    }
    
    static var heightWithSingleLine: CGFloat
    {
        return 2 * padding + TextView.lineHeight
    }
    
    static var padding: CGFloat
    {
        return Float.itemPadding(for: Float(TextView.lineHeight)).cgFloat
    }
    
    static var spacing: CGFloat
    {
        return TextView.lineSpacing
    }
    
    // MARK: - Data
    
    static let uiIdentifier = NSUserInterfaceItemIdentifier(rawValue: "TaskViewID")
    
    private(set) weak var task: Task?
    
    // MARK: - Observability
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event: Equatable
    {
        case didNothing
        case willEditTitle
        case didChangeTitle
        case wantToEndEditingText
        case didEditTitle
        case wasClicked(withCmd: Bool)
    }
}
