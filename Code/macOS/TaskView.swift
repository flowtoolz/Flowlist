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
        
        observe(darkMode)
        {
            [weak self] _ in self?.colorModeDidChange()
        }
        
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
    
    // MARK: - Configuration
    
    func configure(with task: Task, selected: Bool)
    {   
        stopObserving(task: self.task)
        observe(task: task)
        self.task = task
        
        isSelected = selected
        
        // color overlay & border color
        
        let isDone = task.isDone
        let isTagged = task.tag.value != nil
        
        colorOverlay.isHidden = !isTagged || isDone
        
        let regularBorderColor = Color.itemBorder(isDone: isDone,
                                                 isSelected: isSelected)
        
        if let tag = task.tag.value
        {
            let tagColor = Color.tags[tag.rawValue]
            
            colorOverlay.backgroundColor = tagColor
            
            let border: Color = isDone ? regularBorderColor : tagColor.with(alpha: Color.tagBorderAlpha)
            
            layer?.borderColor = border.cgColor
        }
        else
        {
            layer?.borderColor = regularBorderColor.cgColor
        }
        
        // background color
        
        backgroundColor = .itemBackground(isDone: isDone,
                                          isSelected: isSelected,
                                          isTagged: isTagged)
        
        // text color
        
        textView.set(color: .itemText(isDone: isDone, isSelected: isSelected))
        
        // icon alphas
        
        checkBox.alphaValue = isDone ? Color.doneItemIconAlpha.cgFloat : 1
        groupIcon.alphaValue = isDone ? Color.doneItemIconAlpha.cgFloat : 1
        
        // check box image
        
        let lightContent = Color.itemContentIsLight(isSelected: selected)
        checkBox.configure(with: task.state.value, white: lightContent)
        
        // group icon image
        
        updateGroupIconColor(light: lightContent)
        
        // other
        
        updateTextView()
        updateGroupIcon()
    }
    
    // MARK: - Observing the Task
    
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
            [weak self] _ in self?.tagDidChange()
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
    
    // MARK: - Adapt Colors to State, Tag, Dark Mode & Selection
    
    private func colorModeDidChange()
    {
        let isDone = task?.isDone ?? false
        let isTagged = task?.tag.value != nil
        
        backgroundColor = .itemBackground(isDone: isDone,
                                          isSelected: isSelected,
                                          isTagged: isTagged)
        editingBackground.backgroundColor = .editingBackground
        
        let lightContent = Color.itemContentIsLight(isSelected: isSelected)
        checkBox.set(white: lightContent)
        updateGroupIconColor(light: lightContent)
        
        textView.set(color: .itemText(isDone: isDone,
                                      isSelected: isSelected,
                                      isEditing: isEditing))
        
        textView.insertionPointColor = Color.text.nsColor
        textView.selectedTextAttributes = TextView.selectionSyle
        
        if isDone || !isTagged
        {
            layer?.borderColor = Color.itemBorder(isDone: isDone,
                                                  isSelected: isSelected).cgColor
        }
    }
    
    private func taskStateDidChange()
    {
        guard let task = task else { return }
        
        let isDone = task.isDone
        let isTagged = task.tag.value != nil
        
        backgroundColor = .itemBackground(isDone: isDone,
                                          isSelected: isSelected,
                                          isTagged: isTagged)
        
        checkBox.set(state: task.state.value)
        checkBox.alphaValue = isDone ? Color.doneItemIconAlpha.cgFloat : 1
        groupIcon.alphaValue = isDone ? Color.doneItemIconAlpha.cgFloat : 1
        
        textView.set(color: .itemText(isDone: isDone, isSelected: isSelected))
        
        colorOverlay.isHidden = task.tag.value == nil || isDone
        
        if let tag = task.tag.value
        {
            let tagColor = Color.tags[tag.rawValue]
            
            let regularBorderColor = Color.itemBorder(isDone: isDone,
                                                      isSelected: isSelected)
            
            let border = isDone ? regularBorderColor : tagColor.with(alpha: Color.tagBorderAlpha)
            
            layer?.borderColor = border.cgColor
        }
    }
    
    private func tagDidChange()
    {
        guard let task = task else { return }
        
        let isTagged = task.tag.value != nil
        let isDone = task.isDone
        
        colorOverlay.isHidden = !isTagged || isDone
        
        if let tag = task.tag.value
        {
            let tagColor = Color.tags[tag.rawValue]
            
            colorOverlay.backgroundColor = tagColor
            
            if !isDone
            {
                layer?.borderColor = tagColor.with(alpha: Color.tagBorderAlpha).cgColor
            }
        }
        else
        {
            layer?.borderColor = Color.itemBorder(isDone: isDone,
                                                  isSelected: isSelected).cgColor
        }
    }
    
    override func mouseDown(with event: NSEvent)
    {
        send(.wasClicked(withCmd: event.cmd))
    }
    
    func set(selected: Bool)
    {
        guard isSelected != selected else { return }
        
        isSelected = selected
        
        let isDone = task?.isDone ?? false
        let isTagged = task?.tag.value != nil
        
        backgroundColor = .itemBackground(isDone: isDone,
                                          isSelected: isSelected,
                                          isTagged: isTagged)
        
        if !textView.isEditing
        {
            textView.set(color: .itemText(isDone: isDone,
                                          isSelected: isSelected))
        }
        
        let lightContent = Color.itemContentIsLight(isSelected: isSelected)
        updateGroupIconColor(light: lightContent)
        
        checkBox.set(white: lightContent)
        
        if !isTagged || isDone
        {
            layer?.borderColor = Color.itemBorder(isDone: isDone,
                                                  isSelected: isSelected).cgColor
        }
    }
    
    private(set) var isSelected = false
    
    // MARK: - Adapt to Font Size Changes
    
    private func fontSizeDidChange()
    {
        let itemHeight = TaskView.heightWithSingleLine
        
        for constraint in layoutGuideSizeConstraints
        {
            constraint.constant = itemHeight
        }
        
        textView.fontSizeDidChange()
    }
    
    // MARK: - Color Overlay
    
    private func constrainColorOverlay()
    {
        colorOverlay.constrainToParent()
    }
    
    private lazy var colorOverlay: LayerBackedView =
    {
        let view = addForAutoLayout(LayerBackedView())
        
        view.alphaValue = Color.colorOverlayAlpha.cgFloat
        
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
        
        view.insertionPointColor = Color.text.nsColor
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
            send(.willEditTitle)
            
        case .didChange(let text):
            send(.didChangeTitle)
            task?.title <- String(withNonEmpty: text)
            
        case .wantToEndEditing:
            send(.wantToEndEditingText)
            
        case .didEdit:
            set(editing: false)
            task?.title <- String(withNonEmpty: textView.string)
            send(.didEditTitle)
        }
    }
    
    private func set(editing: Bool)
    {
        isEditing = editing
        
        let isDone = task?.isDone ?? false
        
        textView.set(color: .itemText(isDone: isDone,
                                      isSelected: isSelected,
                                      isEditing: editing))
        
        editingBackground.alphaValue = editing ? 1 : 0
        
        if !editing
        {
            checkBox.isEnabled = true
        }
        
        let iconAlpha: CGFloat = isDone ? Color.doneItemIconAlpha.cgFloat : 1
        
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
        
        groupIcon.animator().alphaValue = editing ? 0 : iconAlpha
        checkBox.animator().alphaValue = editing ? 0 : iconAlpha
        
        NSAnimationContext.endGrouping()
    }
    
    private var isEditing = false
    
    // MARK: - Editing Background
    
    private func constrainEditingBackground()
    {
        editingBackground.constrainToParent(insetTop: 5,
                                            insetLeft: 20,
                                            insetBottom: 5,
                                            insetRight: 20)
    }
    
    private lazy var editingBackground: LayerBackedView =
    {
        let view = addForAutoLayout(LayerBackedView())
        
        view.backgroundColor = .editingBackground
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
        groupIcon.constrainWidth(to: TaskView.groupIconWidthMultiplier,
                                 of: layoutGuide)
    }
    
    private static let groupIconWidthMultiplier: CGFloat = 0.75
    
    private func updateGroupIconColor(light: Bool)
    {
        groupIcon.image = TaskView.groupIconImage(light: light)
    }
    
    private static func groupIconImage(light: Bool) -> NSImage
    {
        return light ? groupIconImageWhite : groupIconImageBlack
    }
    
    private static let groupIconImageBlack = #imageLiteral(resourceName: "container_indicator_pdf")
    private static let groupIconImageWhite = #imageLiteral(resourceName: "container_indicator_white")
    
    private lazy var groupIcon = addForAutoLayout(Icon())
    
    // MARK: - Layout Guide
    
    private func constrainLayoutGuide()
    {
        layoutGuide.constrainLeft(to: self)
        layoutGuide.constrainTop(to: self)
        
        let size = TaskView.heightWithSingleLine
        
        layoutGuideSizeConstraints = layoutGuide.constrainSize(to: size, size)
    }
    
    private var layoutGuideSizeConstraints = [NSLayoutConstraint]()
    
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
