import AppKit
import UIToolz
import SwiftObserver
import SwiftyToolz

class TaskView: LayerBackedView, Observer, Observable
{
    // MARK: - Life Cycle
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        identifier = TaskView.uiIdentifier
        
        constrainLayoutGuide()
        constrainEditingBackground()
        constrainCheckBox()
        contrainGroupIcon()
        constrainTextView()
        
        setItemBorder()
        
        observe(Font.baseSize)
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
        
        updateTextView()
        updateState()
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
            [weak self] _ in self?.updateState()
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
    
    private func updateState()
    {
        let state = task?.state.value
        
        checkBox.update(with: state)
        
        alphaValue = state == .done ? 0.5 : 1.0
    }
    
    private func stopObserving(task: Task?)
    {
        stopObserving(task?.state)
        stopObserving(task?.title)
        stopObserving(task)
    }
    
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
        textView.autoConstrainAttribute(.left,
                                        to: .right,
                                        of: layoutGuide,
                                        withMultiplier: TaskView.textLeftMultiplier)
        textView.autoConstrainAttribute(.right, to: .left, of: groupIcon)
        textView.autoConstrainAttribute(.top, to: .top, of: checkBox)
        textView.autoPinEdge(toSuperviewEdge: .bottom)
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
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.allowsImplicitAnimation = true
        NSAnimationContext.current.duration = 0.2
        groupIcon.alphaValue = editing ? 0 : 1
        checkBox.alphaValue = editing ? 0 : 1
        checkBox.isEnabled = !editing
        editingBackground.alphaValue = editing ? 1 : 0
        NSAnimationContext.endGrouping()
    }
    
    // MARK: - Editing Background
    
    private func constrainEditingBackground()
    {
        let insets = NSEdgeInsets(top: 5, left: 20, bottom: 5, right: 20)
        editingBackground.autoPinEdgesToSuperviewEdges(with: insets)
    }
    
    private lazy var editingBackground: LayerBackedView =
    {
        let view = addForAutoLayout(LayerBackedView())
        
        view.backgroundColor = .white
        view.alphaValue = 0
        view.layer?.cornerRadius = Float.cornerRadius.cgFloat
        view.layer?.borderColor = Color.flowlistBlue.with(alpha: 0.25).cgColor
        view.layer?.borderWidth = 1
        
        return view
    }()
    
    // MARK: - Check Box

    private func constrainCheckBox()
    {
        checkBox.autoMatch(.height,
                           to: .height,
                           of: layoutGuide,
                           withMultiplier: 0.45)
        checkBox.autoMatch(.width, to: .height, of: self)
        
        checkBox.autoAlignAxis(.horizontal, toSameAxisOf: layoutGuide)
        checkBox.autoAlignAxis(.vertical, toSameAxisOf: layoutGuide)
    }
    
    private lazy var checkBox: CheckBox =
    {
        let button = addForAutoLayout(CheckBox())

        button.action = #selector(didClickCheckBox)
        button.target = self
        
        return button
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
        groupIcon.autoPinEdge(toSuperviewEdge: .right)
        groupIcon.autoAlignAxis(.horizontal, toSameAxisOf: checkBox)
        
        groupIcon.autoMatch(.height, to: .height, of: checkBox)
        
        groupIcon.autoMatch(.width,
                            to: .width,
                            of: layoutGuide,
                            withMultiplier: TaskView.groupIconWidthMultiplier)
    }
    
    private static let groupIconWidthMultiplier: CGFloat = 0.75
    
    private lazy var groupIcon: Icon =
    {
        let icon = addForAutoLayout(Icon(with: TaskView.groupIconImage))
        
        icon.imageAlignment = .alignCenter
        
        return icon
    }()
    
    private static let groupIconImage = #imageLiteral(resourceName: "container_indicator_pdf")
    
    // MARK: - Layout Guide
    
    private func constrainLayoutGuide()
    {
        layoutGuide.autoPinEdge(toSuperviewEdge: .left)
        layoutGuide.autoPinEdge(toSuperviewEdge: .top)
        
        layoutGuideHeightConstraint = layoutGuide.autoSetDimension(.height,
                                                                   toSize: TaskView.heightWithSingleLine)
        
        layoutGuideWidthConstraint = layoutGuide.autoSetDimension(.width,
                                                                  toSize: TaskView.heightWithSingleLine)
    }
    
    private var layoutGuideHeightConstraint: NSLayoutConstraint?
    private var layoutGuideWidthConstraint: NSLayoutConstraint?
    
    private lazy var layoutGuide: NSView = addForAutoLayout(NSView())
    
    // MARK: - Measuring Size
    
    static func preferredHeight(for text: String, width: CGFloat) -> CGFloat
    {
        let referenceHeight = heightWithSingleLine
        let leftInset  = CGFloat(Int(referenceHeight * textLeftMultiplier))
        let rightInset = CGFloat(Int(referenceHeight * groupIconWidthMultiplier))
        
        let textWidth = CGFloat(Int((width - (leftInset + rightInset)) + 0.5))
        
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
    
    enum Event
    {
        case didNothing, willEditTitle, didChangeTitle, wantToEndEditingText, didEditTitle
    }
}
