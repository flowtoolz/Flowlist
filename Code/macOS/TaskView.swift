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
        
        constrainCheckBox()
        contrainGroupIndicator()
        constrainTitleField()
        
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
    
    func adjustTo(state: Task.State?)
    {
        let isChecked = state == .done
        
        let correctImage = checkBox.image(isChecked)
        
        if checkBox.image !== correctImage
        {
            checkBox.image = correctImage
            
            titleField.textColor = (isChecked ? Color.grayedOut : Color.black).nsColor
        }
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
    
    // MARK: - Title Field
    
    private func constrainTitleField()
    {
        titleField.autoAlignAxis(.horizontal, toSameAxisOf: self)
        titleField.autoPinEdge(.left, to: .right, of: checkBox)
        titleField.autoPinEdge(.right,
                               to: .left,
                               of: groupIndicator,
                               withOffset: -10)
    }
    
    private lazy var titleField: TextField =
    {
        let textField = TextField("untitled")
        self.addSubview(textField)

        textField.delegate = self
        
        self.observe(textField, filter: { $0 == .didBecomeFirstResponder} )
        {
            [weak self] _ in
            
            self?.send(.didGainFocus)
        }
        
        return textField
    }()
    
    // MARK: - Check Box

    private func constrainCheckBox()
    {
        checkBox.autoConstrainAttribute(.width, to: .height, of: checkBox)
        checkBox.autoPinEdgesToSuperviewEdges(with: NSEdgeInsetsZero,
                                              excludingEdge: .right)
    }
    
    private lazy var checkBox: CheckBox =
    {
        let button = CheckBox.newAutoLayout()
        self.addSubview(button)

        button.action = #selector(didClickCheckBox)
        button.target = self
        
        return button
    }()
    
    @objc private func didClickCheckBox()
    {
        _ = task?.state <- task?.isDone ?? false ? nil : .done
    }
    
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
    
    // MARK: - UI Identifier
    
    static let uiIdentifier = NSUserInterfaceItemIdentifier(rawValue: "TaskViewID")
    
    // MARK: - Task
    
    private(set) weak var task: Task?
    
    // MARK: - Observability
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event { case didNothing, didEndEditing, didGainFocus }
}
