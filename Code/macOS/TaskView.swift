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
        
        constrainCheckBox()
        contrainGroupIndicator()
        constrainTitleField()
        
        setItemBorder()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    deinit
    {
        send(.willDeinit)
        NotificationCenter.default.removeObserver(self)
        stopAllObserving()
    }
    
    // MARK: - Configuration
    
    func configure(with task: Task?) -> TaskView?
    {
        guard let task = task else
        {
            log(error: "Cannot configure task view with nil task.")
            return nil
        }
        
        stopObserving(task: self.task)
        observe(task: task)
        
        self.task = task
        
        updateTitleField()
        updateState()
        updateGroupIndicator()
        
        return self
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
            [weak self] _ in self?.updateTitleField()
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
    
    func editTitle() { titleField.selectText(self) }
    
    private func updateTitleField()
    {
        titleField.stringValue = task?.title.value ?? ""
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
        
        self.observe(textField) { [weak self] in self?.didReceive($0) }
        
        return textField
    }()
    
    private func didReceive(_ event: TextField.Event)
    {
        switch event
        {
        case .didNothing: break
            
        case .willEdit:
            send(.willEditTitle)
            
        case .didChange(let text):
            task?.title <- String(withNonEmpty: text)
            
        case .didEdit:
            task?.title <- String(withNonEmpty: titleField.stringValue)
            send(.didEditTitle)
        }
    }
    
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
        groupIndicator.isHidden = !(task?.hasBranches ?? false)
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
    
    enum Event { case didNothing, willEditTitle, didEditTitle, willDeinit }
}
