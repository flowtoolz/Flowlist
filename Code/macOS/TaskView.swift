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
        
        setItemBorder()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    deinit
    {
        NotificationCenter.default.removeObserver(self)
        stopAllObserving()
    }
    
    // MARK: - Configuration
    
    func configure(with task: Task)
    {
        stopObserving(task: self.task)
        observe(task: task)
        
        self.task = task
        
        updateTitle()
        updateState()
        updateGroupIndicator()
    }
    
    private func observe(task: Task)
    {
        observe(task)
        {
            [weak self] event in
            
            if event.itemsDidChange { self?.updateGroupIndicator() }
        }
        
        observe(task.title)
        {
            [weak self] _ in self?.updateTitle()
        }
        
        observe(task.state)
        {
            [weak self] _ in self?.updateState()
        }
    }
    
    private func updateState()
    {
        let state = self.task?.state.value
        checkBox.update(with: state)
        titleField.update(with: state)
    }
    
    private func stopObserving(task: Task?)
    {
        stopObserving(task?.state)
        stopObserving(task?.title)
        stopObserving(task)
    }
    
    // MARK: - Title Field
    
    private func updateTitle()
    {
        titleField.stringValue = task?.title.value ?? ""
    }
    
    func editTitle() { titleField.selectText(self) }
    
    func control(_ control: NSControl,
                 textShouldEndEditing fieldEditor: NSText) -> Bool
    {
        task?.title <- String(withNonEmpty: fieldEditor.string)
        
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didEditTitle),
                                               name: NSText.didEndEditingNotification,
                                               object: fieldEditor)
        
        return true
    }
    
    @objc private func didEditTitle()
    {
        NotificationCenter.default.removeObserver(self)
        
        send(.didEditTitle)
    }
    
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
        
        self.observe(textField, select: .willBecomeFirstResponder)
        {
            [weak self] in self?.send(.didGainFocus)
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
        task?.state <- task?.isDone ?? false ? nil : .done
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
    
    private lazy var groupIndicator: GroupIndicator =
    {
        let view = GroupIndicator.newAutoLayout()
        self.addSubview(view)
        
        return view
    }()
    
    // MARK: - Data
    
    static let uiIdentifier = NSUserInterfaceItemIdentifier(rawValue: "TaskViewID")
    
    private(set) weak var task: Task?
    
    // MARK: - Observability
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event { case didNothing, didEditTitle, didGainFocus }
}
