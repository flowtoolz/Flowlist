import AppKit
import SwiftObserver
import SwiftyToolz

class TaskView: NSView, NSTextFieldDelegate, Observer, Observable
{
    // MARK: - Life Cycle
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        identifier = TaskView.uiIdentifier
        
        layoutCheckBox()
        contrainGroupIndicator()
        layoutTitleField()
        
        wantsLayer = true
        layer?.borderColor = Color.border.nsColor.cgColor
        layer?.borderWidth = 1.0
        layer?.cornerRadius = 4.0
    }
    
    required init?(coder: NSCoder)
    {
        fatalError("init?(coder: NSCoder) not implemented in TaskView")
    }
    
    deinit
    {
        NotificationCenter.default.removeObserver(self)
        stopAllObserving()
    }
    
    // MARK: - Configuration
    
    func configure(with task: Task)
    {
        stopObserving(task: self.task)
        
        self.task = task
        
        observe(task: task)
        
        titleField.stringValue = task.title.value ?? ""
        adjustTo(state: task.state.value)
        updateGroupIndicator()
    }
    
    private func observe(task: Task)
    {
        observe(task)
        {
            [weak self] event in
            
            if event.itemsDidChange
            {
                self?.updateGroupIndicator()
            }
        }
        
        observe(task.title)
        {
            [weak self] update in
            
            self?.titleField.stringValue = update.new ?? ""
        }
        
        observe(task.state)
        {
            [weak self] update in
            
            self?.adjustTo(state: update.new)
        }
    }
    
    private func stopObserving(task: Task?)
    {
        stopObserving(task?.state)
        stopObserving(task?.title)
        stopObserving(task)
    }
    
    // MARK: - Title Editing
    
    func startEditingTitle()
    {
        titleField.selectText(self)
    }
    
    var isTitleEditingEnabled: Bool
    {
        set { titleField.isEditable = newValue }
        
        get { return titleField.isEditable }
    }
    
    func control(_ control: NSControl,
                 textShouldEndEditing fieldEditor: NSText) -> Bool
    {
        newTitle = String(withNonEmpty: fieldEditor.string)
        
        NotificationCenter.default.removeObserver(self)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didEndEditing),
                                               name: NSText.didEndEditingNotification,
                                               object: fieldEditor)
        
        return true
    }
    
    @objc func didEndEditing()
    {        
        _ = task?.title <- newTitle
        
        NotificationCenter.default.removeObserver(self)
        
        send(.didEndEditing)
    }
    
    private var newTitle: String?
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event { case didNothing, didEndEditing }
    
    // MARK: - Title Field
    
    private func layoutTitleField()
    {
        titleField.autoAlignAxis(.horizontal, toSameAxisOf: self)
        titleField.autoPinEdge(.left, to: .right, of: checkBox)
        titleField.autoPinEdge(.right,
                               to: .left,
                               of: groupIndicator,
                               withOffset: -5)
    }
    
    lazy var titleField: TextField =
    {
        let textField = TextField()
        self.addSubview(textField)
        
        textField.isBordered = false
        textField.drawsBackground = false
        textField.isBezeled = false
        textField.isEditable = true
        textField.font = NSFont.systemFont(ofSize: 13)
        textField.delegate = self
        textField.lineBreakMode = .byTruncatingTail
        
        
        let attributes: [NSAttributedStringKey : Any] =
        [
            NSAttributedStringKey.foregroundColor: self.greyedOutColor,
            NSAttributedStringKey.font: NSFont.systemFont(ofSize: 13)
        ]
        
        let attributedString = NSAttributedString(string: "untitled",
                                                  attributes: attributes)
        
        textField.placeholderAttributedString = attributedString
        
        return textField
    }()
    
    // MARK: - Check Box
    
    @objc func checkBoxClicked()
    {
        _ = task?.state <- task?.isDone ?? false ? nil : .done
    }
    
    func adjustTo(state: Task.State?)
    {
        let isChecked = state == .done
        
        let correctImage = checkBoxImage(isChecked)
        
        if checkBox.image !== correctImage
        {
            checkBox.image = correctImage
            
            titleField.textColor = isChecked ? greyedOutColor : NSColor.black
        }
    }

    private func layoutCheckBox()
    {
        checkBox.autoPinEdgesToSuperviewEdges(with: NSEdgeInsetsZero, excludingEdge: .right)
        checkBox.autoSetDimension(.width, toSize: 36)
    }
    
    private lazy var checkBox: NSButton =
    {
        let button = NSButton.newAutoLayout()
        self.addSubview(button)
        
        button.bezelStyle = NSButton.BezelStyle.regularSquare
        button.title = ""
        button.action = #selector(checkBoxClicked)
        button.target = self
        button.imageScaling = .scaleNone
        button.image = TaskView.checkBoxImageEmpty
        button.isBordered = false
        button.layer?.backgroundColor = NSColor.clear.cgColor
        
        return button
    }()
    
    private lazy var greyedOutColor = NSColor(white: 0, alpha: 0.33)
    
    private func checkBoxImage(_ checked: Bool) -> NSImage?
    {
        return checked ? TaskView.checkBoxImageChecked : TaskView.checkBoxImageEmpty
    }
    
    private static let checkBoxImageEmpty = NSImage(named: NSImage.Name(rawValue: "checkbox_unchecked"))
    private static let checkBoxImageChecked = NSImage(named: NSImage.Name(rawValue: "checkbox_checked"))
    
    // MARK: - Group Indicator
    
    private func updateGroupIndicator()
    {
        groupIndicator.isHidden = !(task?.hasSubtasks ?? false)
    }
    
    private func contrainGroupIndicator()
    {
        groupIndicator.autoAlignAxis(toSuperviewAxis: .horizontal)
        groupIndicator.autoPinEdge(toSuperviewEdge: .right, withInset: 10)
    }
    
    private lazy var groupIndicator: NSImageView =
    {
        let view = NSImageView.newAutoLayout()
        self.addSubview(view)
        
        view.image = NSImage(named: NSImage.Name(rawValue: "group_indicator"))
        view.imageScaling = .scaleNone
        view.imageAlignment = .alignCenter
        view.isHidden = true
        
        return view
    }()
    
    // MARK: - Table View Cell
    
    static let uiIdentifier = NSUserInterfaceItemIdentifier(rawValue: "TaskViewID")
    
    // MARK: - Task
    
    private(set) weak var task: Task?
}
