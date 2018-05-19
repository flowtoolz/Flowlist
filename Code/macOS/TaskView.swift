import AppKit
import SwiftObserver

class TaskView: NSView, NSTextFieldDelegate, Observer
{
    // MARK: - Life Cycle
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        initialize()
    }
    
    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        
        initialize()
    }
    
    private func initialize()
    {
        identifier = NSUserInterfaceItemIdentifier(rawValue: TaskView.reuseIdentifier)
        
        layoutCheckBox()
        layoutContainerIndicator()
        layoutTitleField()
        
        wantsLayer = true
        layer?.borderColor = TaskView.borderColor.cgColor
        layer?.borderWidth = 1.0
        layer?.cornerRadius = 4.0
    }
    
    deinit
    {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Configuration
    
    func configure(with task: Task)
    {
        self.task = task
        
        updateTitleField()
        updateCheckBox()
        updateGroupIndicator()
    }
    
    // MARK: - Title Field
    
    func updateTitleField()
    {
        titleField.stringValue = self.task?.title.value ?? ""
    }
    
    func startEditingTitle()
    {
        titleField.selectText(self)
    }
    
    var isTitleEditingEnabled: Bool
    {
        set
        {
            titleField.isEditable = newValue
        }
        
        get
        {
            return titleField.isEditable
        }
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
    }
    
    private var newTitle: String?
    
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
        
        updateCheckBox()
    }
    
    func updateCheckBox()
    {
        let isChecked = task?.isDone ?? false
        
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
    
    func updateGroupIndicator()
    {
        groupIndicator.isHidden = !(task?.hasSubtasks ?? false)
    }
    
    private func layoutContainerIndicator()
    {
        groupIndicator.autoPinEdgesToSuperviewEdges(with: NSEdgeInsetsZero,
                                                        excludingEdge: .left)
        groupIndicator.autoSetDimension(.width, toSize: 22)
    }
    
    private lazy var groupIndicator: NSImageView =
    {
        let view = NSImageView.newAutoLayout()
        self.addSubview(view)
        
        view.image = NSImage(named: NSImage.Name(rawValue: "container_indicator"))
        view.imageScaling = .scaleNone
        view.imageAlignment = .alignCenter
        view.isHidden = true
        
        return view
    }()
    
    // MARK: - Task
    
    private weak var task: Task?
    
    static let verticalGap: CGFloat = 2
    
    static let selectionColor = NSColor(calibratedRed: 163.0/255.0,
                                         green: 205.0 / 255.0,
                                         blue: 254.0 / 255.0,
                                         alpha: 1)
    
    static let doneColor = NSColor(calibratedRed: 225.0/255.0,
                                    green: 225.0 / 255.0,
                                    blue: 225.0 / 255.0,
                                    alpha: 1)
    
    static let borderColor = NSColor.black.withAlphaComponent(0.15)
    
    class TextField: NSTextField
    {
        override func becomeFirstResponder() -> Bool
        {
            let didBecomeFirstResponder = super.becomeFirstResponder()
            
            if didBecomeFirstResponder
            {
                taskViewTextFieldDelegate?.taskViewTextFieldDidBecomeFirstResponder(self)
            }
            
            return didBecomeFirstResponder
        }
        
        weak var taskViewTextFieldDelegate: TaskViewTextFieldDelegate?
    }
    
    // MARK: - Table View Cell
    
    static let reuseIdentifier = "TaskListCellIdentifier"
}

protocol TaskViewTextFieldDelegate: AnyObject
{
    func taskViewTextFieldDidBecomeFirstResponder(_ textField: TaskView.TextField)
}
