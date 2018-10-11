import AppKit
import UIToolz
import SwiftObserver
import SwiftyToolz
import GetLaid

class ItemView: LayerBackedView, Observer, Observable
{
    // MARK: - Life Cycle
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        identifier = ItemView.uiIdentifier
        
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
    
    // MARK: - Configuration
    
    func configure(with task: Item, selected: Bool)
    {
        stopObserving(task: self.task)
        observe(task: task)
        self.task = task
        
        guard let itemData = task.data else
        {
            log(error: "Tried to configure Item which has no data")
            return
        }
        
        isSelected = selected
        isFocused = itemData.isFocused.latestUpdate
        
        // color overlay
        
        let isDone = task.isDone
        let isTagged = itemData.tag.value != nil
        
        colorOverlay.isHidden = !isTagged || isDone
        
        if let tag = itemData.tag.value
        {
            colorOverlay.backgroundColor = Color.tags[tag.rawValue]
        }
        
        colorOverlay.alphaValue = selected ? 1 : 0.5
        
        // background color
        
        backgroundColor = .itemBackground(isDone: isDone,
                                          isSelected: isSelected,
                                          isTagged: isTagged,
                                          isFocusedList: isFocused)
        
        // text color
        
        textView.set(color: .itemText(isDone: isDone,
                                      isSelected: isSelected,
                                      isFocused: isFocused))
        
        // icon alphas
        
        checkBox.alphaValue = Color.iconAlpha(isInProgress: task.isInProgress,
                                              isDone: isDone,
                                              isSelected: isSelected).cgFloat
        groupIcon.alphaValue = Color.iconAlpha(isInProgress: false,
                                               isDone: isDone,
                                               isSelected: isSelected).cgFloat
        
        // check box image
        
        let lightContent = Color.itemContentIsLight(isSelected: selected,
                                                    isFocused: isFocused)
        checkBox.configure(with: task.data?.state.value, white: lightContent)
        
        // group icon image
        
        updateGroupIconColor(light: lightContent)
        
        // other
        
        updateTextView()
        updateGroupIcon()
    }
    
    // MARK: - Observing the Item
    
    private func observe(task: Item)
    {
        observe(task)
        {
            [weak self, weak task] event in
            
            guard let task = task else { return }
            
            self?.received(event, from: task)
        }
        
        guard let itemData = task.data else
        {
            log(error: "Tried to observe item which has no data object")
            return
        }
        
        observe(itemData: itemData)
    }
    
    private func received(_ event: Item.Event, from task: Item)
    {
        switch event
        {
        case .didNothing: break
        
        case .did(let edit): if edit.modifiesContent { updateGroupIcon() }
        case .didChangeData(let from, let to): didSwitch(from: from, to: to)
        case .didChange(numberOfLeafs: _): break
        }
    }
    
    private func didSwitch(from oldItemData: ItemData?,
                           to newItemData: ItemData?)
    {
        stopObserving(itemData: oldItemData)
        
        guard let new = newItemData else { return }
        
        observe(itemData: new)
    }
    
    private func observe(itemData: ItemData)
    {
        observe(itemData)
        {
            [weak self] event in
            
            if event == .wantTextInput
            {
                self?.textView.startEditing()
            }
        }
        
        observe(itemData.state)
        {
            [weak self] _ in self?.taskStateDidChange()
        }
        
        observe(itemData.tag)
        {
            [weak self] _ in self?.tagDidChange()
        }
        
        observe(itemData.isFocused)
        {
            [weak self] isFocused in self?.set(focused: isFocused)
        }
    }
    
    private func stopObserving(itemData: ItemData?)
    {
        stopObserving(itemData)
        stopObserving(itemData?.state)
        stopObserving(itemData?.tag)
        stopObserving(itemData?.isFocused)
    }
    
    private func stopObserving(task: Item?)
    {
        stopObserving(task?.data?.state)
        stopObserving(task?.data?.title)
        stopObserving(task)
    }
    
    // MARK: - Adapt Colors to State, Tag, Dark Mode & Selection
    
    private func colorModeDidChange()
    {
        let isDone = task?.isDone ?? false
        let isTagged = task?.data?.tag.value != nil
        
        backgroundColor = .itemBackground(isDone: isDone,
                                          isSelected: isSelected,
                                          isTagged: isTagged,
                                          isFocusedList: isFocused)
        
        editingBackground.backgroundColor = .editingBackground
        
        let lightContent = Color.itemContentIsLight(isSelected: isSelected,
                                                    isFocused: isFocused)
        checkBox.set(white: lightContent)
        updateGroupIconColor(light: lightContent)
        
        textView.set(color: .itemText(isDone: isDone,
                                      isSelected: isSelected,
                                      isFocused: isFocused,
                                      isEditing: isEditing))
        
        textView.insertionPointColor = Color.text.nsColor
        textView.selectedTextAttributes = TextView.selectionSyle
        
        let isInProgress = task?.isInProgress ?? false
        checkBox.alphaValue = Color.iconAlpha(isInProgress: isInProgress,
                                              isDone: isDone,
                                              isSelected: isSelected).cgFloat
        groupIcon.alphaValue = Color.iconAlpha(isInProgress: false,
                                               isDone: isDone,
                                               isSelected: isSelected).cgFloat
    }
    
    private func taskStateDidChange()
    {
        guard let task = task else { return }
        
        let isDone = task.isDone
        let isTagged = task.data?.tag.value != nil
        
        backgroundColor = .itemBackground(isDone: isDone,
                                          isSelected: isSelected,
                                          isTagged: isTagged,
                                          isFocusedList: isFocused)
        
        checkBox.set(state: task.data?.state.value)
        
        checkBox.alphaValue = Color.iconAlpha(isInProgress: task.isInProgress,
                                              isDone: isDone,
                                              isSelected: isSelected).cgFloat
        groupIcon.alphaValue = Color.iconAlpha(isInProgress: false,
                                               isDone: isDone,
                                               isSelected: isSelected).cgFloat
        
        textView.set(color: .itemText(isDone: isDone,
                                      isSelected: isSelected,
                                      isFocused: isFocused))
        
        colorOverlay.isHidden = task.data?.tag.value == nil || isDone
    }
    
    private func tagDidChange()
    {
        guard let task = task else { return }
        
        let isTagged = task.data?.tag.value != nil
        let isDone = task.isDone
        
        colorOverlay.isHidden = !isTagged || isDone
        
        if let tag = task.data?.tag.value
        {
            let tagColor = Color.tags[tag.rawValue]
            
            colorOverlay.backgroundColor = tagColor
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
        let isTagged = task?.data?.tag.value != nil
        
        backgroundColor = .itemBackground(isDone: isDone,
                                          isSelected: isSelected,
                                          isTagged: isTagged,
                                          isFocusedList: isFocused)
        
        if !textView.isEditing
        {
            textView.set(color: .itemText(isDone: isDone,
                                          isSelected: isSelected,
                                          isFocused: isFocused))
            
            let isInProgress = task?.isInProgress ?? false
            checkBox.alphaValue = Color.iconAlpha(isInProgress: isInProgress,
                                                  isDone: isDone,
                                                  isSelected: isSelected).cgFloat
            groupIcon.alphaValue = Color.iconAlpha(isInProgress: false,
                                                   isDone: isDone,
                                                   isSelected: isSelected).cgFloat
        }
        
        if !Color.isInDarkMode
        {
            let lightContent = Color.itemContentIsLight(isSelected: isSelected,
                                                        isFocused: isFocused)
            updateGroupIconColor(light: lightContent)
            
            checkBox.set(white: lightContent)
        }
        
        colorOverlay.alphaValue = selected ? 1 : 0.5
    }
    
    private(set) var isSelected = false
    
    // MARK: - List Focus
    
    private func set(focused: Bool)
    {
        isFocused = focused
        
        guard isSelected, let task = task else { return }
        
        let isDone = task.isDone
        let isTagged = task.data?.tag.value != nil
        
        backgroundColor = .itemBackground(isDone: isDone,
                                          isSelected: isSelected,
                                          isTagged: isTagged,
                                          isFocusedList: isFocused)
        
        if !Color.isInDarkMode
        {
            if !isEditing
            {
                textView.set(color: .itemText(isDone: isDone,
                                              isSelected: isSelected,
                                              isFocused: isFocused))
            }
            
            let lightContent = Color.itemContentIsLight(isSelected: isSelected,
                                                        isFocused: isFocused)
            updateGroupIconColor(light: lightContent)
            checkBox.set(white: lightContent)
        }
    }
    
    private var isFocused = false
    
    // MARK: - Adapt to Font Size Changes
    
    private func fontSizeDidChange()
    {
        let itemHeight = ItemView.heightWithSingleLine
        
        for constraint in layoutGuideSizeConstraints
        {
            constraint.constant = itemHeight
        }
        
        textView.fontSizeDidChange()
    }
    
    // MARK: - Color Overlay
    
    private func constrainColorOverlay()
    {
        colorOverlay.constrainToParentExcludingRight()
        colorOverlay.constrainWidth(to: 0.125, of: layoutGuide)
    }
    
    private lazy var colorOverlay = addForAutoLayout(LayerBackedView())
    
    // MARK: - Text View
    
    private func updateTextView()
    {
        // TODO: is this still needed from El Capitan onwards?
        // https://stackoverflow.com/questions/19121367/uitextviews-in-a-uitableview-link-detection-bug-in-ios-7
        textView.string = ""
        textView.string = task?.data?.title.value ?? ""
    }
    
    private func constrainTextView()
    {
        textView.constrainLeft(to: ItemView.textLeftMultiplier, of: layoutGuide)
        textView.constrain(toTheLeftOf: groupIcon)
        textView.constrainTop(to: 0.303, of: layoutGuide)
        textView.constrainBottomToParent()
    }
    
    private static let textLeftMultiplier = Float.relativeTextInset.cgFloat
    
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
            task?.data?.title <- String(withNonEmpty: text)
            
        case .wantToEndEditing:
            send(.wantToEndEditingText)
            
        case .didEdit:
            set(editing: false)
            task?.data?.title <- String(withNonEmpty: textView.string)
            send(.didEditTitle)
        }
    }
    
    // MARK: - Editing
    
    private func set(editing: Bool)
    {
        isEditing = editing
        
        let isDone = task?.isDone ?? false
        
        textView.set(color: .itemText(isDone: isDone,
                                      isSelected: isSelected,
                                      isFocused: isFocused,
                                      isEditing: editing))
        
        editingBackground.alphaValue = editing ? 1 : 0
        
        if !editing
        {
            checkBox.button.isEnabled = true
        }
        
        let isInProgress = task?.isInProgress ?? false
        let checkBoxAlpha = Color.iconAlpha(isInProgress: isInProgress,
                                            isDone: isDone,
                                            isSelected: isSelected).cgFloat
        let groupIconAlpha = Color.iconAlpha(isInProgress: false,
                                             isDone: isDone,
                                             isSelected: isSelected).cgFloat
        
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.allowsImplicitAnimation = false
        NSAnimationContext.current.duration = 0.2
        NSAnimationContext.current.completionHandler =
        {
            if editing
            {
                self.checkBox.button.isEnabled = false
            }
        }
        
        groupIcon.animator().alphaValue = editing ? 0 : groupIconAlpha
        checkBox.animator().alphaValue = editing ? 0 : checkBoxAlpha
        
        NSAnimationContext.endGrouping()
    }
    
    private var isEditing = false
    
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
        view.layer?.cornerRadius = Float.listCornerRadius.cgFloat
        
        return view
    }()
    
    // MARK: - Check Box
    
    private func constrainCheckBox()
    {
        checkBox.constrainSize(to: 0.43, 0.43, of: layoutGuide)
        checkBox.constrainCenter(to: layoutGuide)
    }
    
    private lazy var checkBox: CheckBox =
    {
        let box = addForAutoLayout(CheckBox())
        
        box.button.action = #selector(didClickCheckBox)
        box.button.target = self
        
        return box
    }()
    
    @objc private func didClickCheckBox()
    {
        task?.data?.state <- task?.isDone ?? false ? nil : .done
    }
    
    // MARK: - Group Icon
    
    private func updateGroupIcon()
    {
        groupIcon.isHidden = task?.isLeaf ?? true
    }
    
    private func contrainGroupIcon()
    {
        groupIcon.constrainRightToParent()
        groupIcon.constrainCenterY(to: layoutGuide)
        groupIcon.constrainHeight(to: checkBox)
        groupIcon.constrainWidth(to: ItemView.groupIconWidthMultiplier,
                                 of: layoutGuide)
    }
    
    private static let groupIconWidthMultiplier: CGFloat = 0.75
    
    private func updateGroupIconColor(light: Bool)
    {
        groupIcon.image = ItemView.groupIconImage(light: light)
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
        
        let size = ItemView.heightWithSingleLine
        
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
    
    private(set) weak var task: Item?
    
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
