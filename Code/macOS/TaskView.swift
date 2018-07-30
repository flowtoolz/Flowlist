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
        contrainGroupIcon()
        constrainEditingBackground()
        constrainTitleField()
        
        setItemBorder()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    deinit
    {
        stopAllObserving()
        removeObservers()
    }
    
    // MARK: - Height
    
    static func preferredHeight(for title: String, width: CGFloat) -> CGFloat
    {
        let checkBoxWidth: CGFloat = 36
        let groupIconWidth: CGFloat = 26
        let titleWidth = width - (checkBoxWidth + groupIconWidth)
        
        let titleHeight = TextField.intrinsicSize(with: title,
                                                  width: titleWidth).height
        
        return titleHeight + 20
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
        
        updateTitleField()
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
        
        observe(task.title)
        {
            [weak self] _ in self?.updateTitleField()
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
        titleField.update(with: state)
    }
    
    private func stopObserving(task: Task?)
    {
        stopObserving(task?.state)
        stopObserving(task?.title)
        stopObserving(task)
    }
    
    // MARK: - Title Field
    
    func editTitle()
    {
        titleField.startEditing()
    }
    
    private func updateTitleField()
    {
        titleField.stringValue = task?.title.value ?? ""
    }

    private func constrainTitleField()
    {
        titleField.autoPinEdge(.top, to: .top, of: editingBackground)
        titleField.autoPinEdge(.left, to: .left, of: editingBackground)
        titleField.autoPinEdge(.right, to: .right, of: editingBackground)
        titleField.autoPinEdge(.bottom, to: .bottom, of: editingBackground)
    }
    
    private lazy var titleField: TextField =
    {
        let textField = addForAutoLayout(TextField())
        
        self.observe(textField) { [weak self] in self?.didReceive($0) }
        
        return textField
    }()
    
    private func didReceive(_ event: TextField.Event)
    {
        switch event
        {
        case .didNothing: break
            
        case .willEdit:
            editingBackground.isHidden = false
            task?.isBeingEdited = true
            send(.willEditTitle)
            
        case .didChange(let text):
            task?.title <- String(withNonEmpty: text)
            send(.didChangeTitle)
            
        case .didEdit:
            editingBackground.isHidden = true
            task?.title <- String(withNonEmpty: titleField.stringValue)
            task?.isBeingEdited = false
            send(.didEditTitle)
        }
    }
    
    // MARK: - Editing Background
    
    private func constrainEditingBackground()
    {
        editingBackground.autoPinEdge(toSuperviewEdge: .top, withInset: 9)
        editingBackground.autoPinEdge(toSuperviewEdge: .bottom, withInset: 9)
        
        editingBackground.autoPinEdge(.left,
                                      to: .right,
                                      of: checkBox,
                                      withOffset: 10)
        editingBackground.autoPinEdge(.right,
                                      to: .left,
                                      of: groupIcon,
                                      withOffset: -10)
    }
    
    private lazy var editingBackground: LayerBackedView =
    {
        let view = addForAutoLayout(LayerBackedView())
        
        view.backgroundColor = .white
        view.isHidden = true
        view.layer?.cornerRadius = Float.cornerRadius.cgFloat
        view.layer?.borderWidth = 1.0
        view.layer?.borderColor = Color.flowlistBlue.with(alpha: 0.25).cgColor
        
        return view
    }()
    
    // MARK: - Check Box

    private func constrainCheckBox()
    {
        checkBox.autoPinEdge(toSuperviewEdge: .top, withInset: 10)
        checkBox.autoPinEdge(toSuperviewEdge: .left, withInset: 10)
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
        groupIcon.autoPinEdge(toSuperviewEdge: .top, withInset: 10)
        groupIcon.autoPinEdge(toSuperviewEdge: .right, withInset: 10)
    }
    
    private lazy var groupIcon: Icon = addForAutoLayout(Icon(with: #imageLiteral(resourceName: "group_indicator")))
    
    // MARK: - Data
    
    static let uiIdentifier = NSUserInterfaceItemIdentifier(rawValue: "TaskViewID")
    
    private(set) weak var task: Task?
    
    // MARK: - Observability
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event { case didNothing, willEditTitle, didChangeTitle, didEditTitle }
}
