import AppKit
import UIToolz
import SwiftObserver
import SwiftyToolz
import GetLaid

class ItemView: LayerBackedView, Observable, Observer
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
        
        observe(Color.darkMode)
        {
            [weak self] _ in self?.colorModeDidChange()
        }
        
        observe(Font.baseSize)
        {
            [weak self] _ in self?.fontSizeDidChange()
        }
    }
    
    required init?(coder: NSCoder) { nil }
    
    // MARK: - Configuration
    
    func configure(with item: Item)
    {
        stopObserving(item: self.item)
        observe(item: item)
        self.item = item
        
        configure()
    }
    
    private func configure()
    {
        guard let item = item else
        {
            return log(error: "Tried to configure ItemView which has no item")
        }
        
        isSelected = item.isSelected
        isFocused = item.isFocused
        
        // color overlay
        
        let isDone = item.data.state.value == .done
        let isTagged = item.data.tag.value != nil
        
        colorOverlay.isHidden = !isTagged || isDone
        
        if let tag = item.data.tag.value
        {
            colorOverlay.backgroundColor = Color.tags[tag.rawValue]
        }
        
        colorOverlay.alphaValue = isSelected ? 1 : 0.5
        
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
        
        let isInProgress = item.data.state.value == .inProgress
        
        checkBox.alphaValue = Color.iconAlpha(isInProgress: isInProgress,
                                              isDone: isDone,
                                              isSelected: isSelected).cgFloat
        groupIcon.alphaValue = Color.iconAlpha(isInProgress: false,
                                               isDone: isDone,
                                               isSelected: isSelected).cgFloat
        
        // check box image
        
        let lightContent = Color.itemContentIsLight(isSelected: isSelected,
                                                    isFocused: isFocused)
        checkBox.configure(with: item.data.state.value, white: lightContent)
        
        // group icon image
        
        groupIcon.set(lightMode: lightContent)
        
        // other
        
        updateTextView()
        updateGroupIcon()
    }
    
    // MARK: - Observing the Item
    
    private func observe(item: Item)
    {
        observe(item.treeMessenger)
        {
            [weak self, weak item] event in
            guard let item = item else { return }
            self?.received(event, from: item)
        }
        
        observe(itemData: item.data)
    }
    
    private func received(_ event: Item.Event, from item: Item)
    {
        switch event
        {
        case .didUpdateTree: break
        case .didUpdateNode(let edit):
            switch edit
            {
            case .switchedParent:
                stopObserving(item: self.item)

            default: break
            }
            
            if edit.modifiesGraphStructure { updateGroupIcon() }
            
        case .didChangeLeafNumber(numberOfLeafs: _): break
        }
    }
    
    private func stopObserving(item: Item?)
    {
        guard let item = item else { return }
        
        stopObserving(item.treeMessenger)
        stopObserving(itemData: item.data)
    }
    
    // MARK: - Observing the Item Data
    
    private func observe(itemData: ItemData)
    {
        observe(itemData)
        {
            [weak self, weak itemData] event in
            
            guard let me = self,
                let data = itemData,
                event == .wantTextInput,
                me.checkIsInWindow(for: data) else { return }
            
            if me.textView.startEditing()
            {
                data.startedEditing()
            }
        }
        
        observe(itemData.text)
        {
            [weak self] textUpdate in
            
            guard let me = self,
                me.checkIsInWindow(for: itemData),
                !me.isEditing else { return }
            
            me.textView.string = textUpdate.new ?? ""
        }
        
        observe(itemData.state)
        {
            [weak self] _ in
            
            guard self?.checkIsInWindow(for: itemData) ?? false else { return }
            
            self?.itemStateDidChange()
        }
        
        observe(itemData.tag)
        {
            [weak self] _ in
            
            guard self?.checkIsInWindow(for: itemData) ?? false else { return }
            
            self?.tagDidChange()
        }
        
        observe(itemData.isFocused)
        {
            [weak self] update in
            
            guard self?.checkIsInWindow(for: itemData) ?? false else { return }
            
            self?.set(focused: update.new)
        }
        
        observe(itemData.isSelected)
        {
            [weak self] update in
            
            guard self?.checkIsInWindow(for: itemData) ?? false else { return }
            
            self?.set(selected: update.new)
        }
    }
    
    private func checkIsInWindow(for itemData: ItemData) -> Bool
    {
        guard window != nil else
        {
            stopObserving(itemData: itemData)
            return false
        }
        
        return true
    }
    
    private func stopObserving(itemData: ItemData?)
    {
        guard let data = itemData else { return }
        
        stopObserving(data)
        stopObserving(data.text)
        stopObserving(data.state)
        stopObserving(data.tag)
        stopObserving(data.isFocused)
        stopObserving(data.isSelected)
    }
    
    // MARK: - Adapt Colors to State, Tag, Dark Mode, Selection, Focus ...
    
    private func colorModeDidChange()
    {
        let isDone = item?.isDone ?? false
        let isTagged = item?.data.tag.value != nil
        
        backgroundColor = .itemBackground(isDone: isDone,
                                          isSelected: isSelected,
                                          isTagged: isTagged,
                                          isFocusedList: isFocused)
        
        editingBackground.backgroundColor = .editingBackground
        
        let lightContent = Color.itemContentIsLight(isSelected: isSelected,
                                                    isFocused: isFocused)
        checkBox.set(white: lightContent)
        groupIcon.set(lightMode: lightContent)
        
        textView.set(color: .itemText(isDone: isDone,
                                      isSelected: isSelected,
                                      isFocused: isFocused,
                                      isEditing: isEditing))
        
        textView.insertionPointColor = Color.text.nsColor
        textView.selectedTextAttributes = TextView.selectionSyle
        
        if !isEditing
        {
            let isInProgress = item?.isInProgress ?? false
            checkBox.alphaValue = Color.iconAlpha(isInProgress: isInProgress,
                                                  isDone: isDone,
                                                  isSelected: isSelected).cgFloat
            groupIcon.alphaValue = Color.iconAlpha(isInProgress: false,
                                                   isDone: isDone,
                                                   isSelected: isSelected).cgFloat
        }
    }
    
    private func itemStateDidChange()
    {
        guard let item = item else { return }
        
        let isDone = item.isDone
        let isTagged = item.data.tag.value != nil
        
        backgroundColor = .itemBackground(isDone: isDone,
                                          isSelected: isSelected,
                                          isTagged: isTagged,
                                          isFocusedList: isFocused)
        
        checkBox.set(state: item.data.state.value)
        
        checkBox.alphaValue = Color.iconAlpha(isInProgress: item.isInProgress,
                                              isDone: isDone,
                                              isSelected: isSelected).cgFloat
        groupIcon.alphaValue = Color.iconAlpha(isInProgress: false,
                                               isDone: isDone,
                                               isSelected: isSelected).cgFloat
        
        textView.set(color: .itemText(isDone: isDone,
                                      isSelected: isSelected,
                                      isFocused: isFocused))
        
        colorOverlay.isHidden = item.data.tag.value == nil || isDone
    }
    
    private func tagDidChange()
    {
        guard let item = item else { return }
        
        let isTagged = item.data.tag.value != nil
        let isDone = item.isDone
        
        colorOverlay.isHidden = !isTagged || isDone
        
        if let tag = item.data.tag.value
        {
            let tagColor = Color.tags[tag.rawValue]
            
            colorOverlay.backgroundColor = tagColor
        }
    }
    
    override func mouseDown(with event: NSEvent)
    {
        send(.wasClicked(withEvent: event))
    }
    
    private func set(selected: Bool)
    {
        guard isSelected != selected else { return }
        
        isSelected = selected
        
        let isDone = item?.isDone ?? false
        let isTagged = item?.data.tag.value != nil
        
        backgroundColor = .itemBackground(isDone: isDone,
                                          isSelected: isSelected,
                                          isTagged: isTagged,
                                          isFocusedList: isFocused)
        
        if !textView.isEditing
        {
            textView.set(color: .itemText(isDone: isDone,
                                          isSelected: isSelected,
                                          isFocused: isFocused))
            
            textView.selectedTextAttributes = TextView.selectionSyle
            
            let isInProgress = item?.isInProgress ?? false
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
            
            groupIcon.set(lightMode: lightContent)
            checkBox.set(white: lightContent)
        }
        
        colorOverlay.alphaValue = selected ? 1 : 0.5
    }
    
    private(set) var isSelected = false
    
    private func set(focused: Bool)
    {
        isFocused = focused
        
        guard isSelected, let item = item else { return }
        
        let isDone = item.isDone
        let isTagged = item.data.tag.value != nil
        
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
                
                textView.selectedTextAttributes = TextView.selectionSyle
            }
            
            let lightContent = Color.itemContentIsLight(isSelected: isSelected,
                                                        isFocused: isFocused)
            
            groupIcon.set(lightMode: lightContent)
            checkBox.set(white: lightContent)
        }
    }
    
    private var isFocused = false
    
    // MARK: - Adapt to Font Size Changes
    
    private func fontSizeDidChange()
    {
        let itemHeight = ItemView.heightWithSingleLine
        
        layoutGuideSizeConstraints.forEach { $0.constant = itemHeight }
        
        textView.fontSizeDidChange()
    }
    
    // MARK: - Color Overlay
    
    private func constrainColorOverlay()
    {
        colorOverlay >> allButRight
        colorOverlay >> layoutGuide.width.at(0.125)
    }
    
    private lazy var colorOverlay = addForAutoLayout(LayerBackedView())
    
    // MARK: - Text View
    
    private func updateTextView()
    {
        // https://stackoverflow.com/questions/19121367/uitextviews-in-a-uitableview-link-detection-bug-in-ios-7
        textView.string = ""
        textView.string = item?.text ?? ""
    }
    
    private func constrainTextView()
    {
        textView.left >> layoutGuide.right.at(ItemView.textLeftMultiplier)
        textView.right >> groupIcon.left
        textView.top >> layoutGuide.bottom.at(0.303)
        textView >> bottom
    }
    
    private static let textLeftMultiplier = Float.relativeTextInset.cgFloat
    
    private lazy var textView: TextView =
    {
        let view = addForAutoLayout(TextView())
        
        view.insertionPointColor = Color.text.nsColor
        
        observe(view)
        {
            [weak self] in self?.didReceive($0)
        }
        
        return view
    }()
    
    private func didReceive(_ event: TextView.Event)
    {
        switch event
        {
        case .willEdit:
            set(editing: true)
            send(.willEditText)
            
        case .didChangeText:
            item?.data.text <- String(withNonEmpty: textView.string)
            send(.didChangeText)
            
        case .wantToEndEditing:
            send(.wantToEndEditingText)
            
        case .didEdit:
            set(editing: false)
            item?.data.text <- String(withNonEmpty: textView.string)
            send(.didEditText)
        case .wasClicked: send(.textViewWasClicked)
        }
    }
    
    // MARK: - Editing
    
    private func set(editing: Bool)
    {
        isEditing = editing
        
        let isDone = item?.isDone ?? false
        
        textView.set(color: .itemText(isDone: isDone,
                                      isSelected: isSelected,
                                      isFocused: isFocused,
                                      isEditing: editing))
        
        editingBackground.alphaValue = editing ? 1 : 0
        
        if !editing
        {
            checkBox.button.isEnabled = true
        }
        
        let isInProgress = item?.isInProgress ?? false
        let checkBoxAlpha = Color.iconAlpha(isInProgress: isInProgress,
                                            isDone: isDone,
                                            isSelected: isSelected).cgFloat
        let groupIconAlpha = Color.iconAlpha(isInProgress: false,
                                             isDone: isDone,
                                             isSelected: isSelected).cgFloat
        
        NSAnimationContext.beginGrouping()
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
        editingBackground >> all(topOffset: 5,
                                 leadingOffset: 20,
                                 bottomOffset: -5,
                                 trailingOffset: -20)
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
        checkBox >> layoutGuide.size.at(0.43)
        checkBox >> layoutGuide.center
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
        item?.data.state <- item?.isDone ?? false ? nil : .done
    }
    
    // MARK: - Group Icon
    
    private func updateGroupIcon()
    {
        groupIcon.isHidden = item?.isLeaf ?? true
    }
    
    private func contrainGroupIcon()
    {
        groupIcon >> right
        groupIcon >> layoutGuide.centerY
        groupIcon >> checkBox.height
        groupIcon >> layoutGuide.width.at(Float.groupIconWidthFactor.cgFloat)
    }
    
    private lazy var groupIcon = addForAutoLayout(GroupIcon())
    
    // MARK: - Layout Guide
    
    private func constrainLayoutGuide()
    {
        layoutGuide >> left
        layoutGuide >> top
        
        let size = ItemView.heightWithSingleLine
        
        layoutGuideSizeConstraints = layoutGuide >> size
    }
    
    private var layoutGuideSizeConstraints = [NSLayoutConstraint]()
    
    private lazy var layoutGuide = addLayoutGuide()
    
    // MARK: - Measuring Size
    
    static func preferredHeight(for text: String, width: CGFloat) -> CGFloat
    {
        let pixelsPerPoint = NSApp.mainWindow?.backingScaleFactor ?? 2
        
        let referenceHeight = heightWithSingleLine * pixelsPerPoint
        
        let leftInset  = CGFloat(Int(referenceHeight * textLeftMultiplier + 0.5))
        
        let rightInset = CGFloat(Int(referenceHeight * Float.groupIconWidthFactor.cgFloat + 0.49999))
        
        let textWidth = ((pixelsPerPoint * width) - (leftInset + rightInset)) / pixelsPerPoint
        
        let textHeight = TextView.size(with: text, width: textWidth).height
        
        return textHeight + (2 * padding)
    }
    
    static var heightWithSingleLine: CGFloat
    {
        2 * padding + TextView.lineHeight
    }
    
    static var padding: CGFloat
    {
        Float.itemPadding(for: Float(TextView.lineHeight)).cgFloat
    }
    
    static var spacing: CGFloat
    {
        TextView.lineSpacing
    }
    
    // MARK: - Data
    
    static let uiIdentifier = UIItemID(rawValue: "ItemViewID")
    
    private(set) weak var item: Item?
    
    // MARK: - Observable Observer
    
    let messenger = Messenger<Event>()
    
    enum Event: Equatable
    {
        case willEditText
        case didChangeText
        case wantToEndEditingText
        case didEditText
        case textViewWasClicked
        case wasClicked(withEvent: NSEvent)
    }
    
    let receiver = Receiver()
}
