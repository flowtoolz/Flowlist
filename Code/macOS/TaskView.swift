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
        let checkBoxWidth: CGFloat = CheckBox.size.width
        let groupIconWidth: CGFloat = groupIconImage.size.width
        let iconPadding: CGFloat = 2 * 11 + 2 * TaskView.titleFieldSideMargin
        let titleWidth = width - (checkBoxWidth + groupIconWidth + iconPadding)
        
        let titleHeight = TextView.size(with: title,
                                        width: titleWidth).height
        
        return titleHeight + 22
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
        
        let borderColor: Color = state == .done ? .done : .border
        layer?.borderColor = borderColor.cgColor
    }
    
    private func stopObserving(task: Task?)
    {
        stopObserving(task?.state)
        stopObserving(task?.title)
        stopObserving(task)
    }
    
    // MARK: - Selection
    
    func will(select: Bool)
    {
        titleField.drawsBackground = select
        titleField.backgroundColor = .white
    }
    
    // MARK: - Title View
    
    func editTitle()
    {
        titleField.startEditing()
    }
    
    private func updateTitleField()
    {
        // https://stackoverflow.com/questions/19121367/uitextviews-in-a-uitableview-link-detection-bug-in-ios-7
        titleField.string = ""
        titleField.string = task?.title.value ?? ""
    }

    private func constrainTitleField()
    {
        titleField.autoPinEdge(.left,
                               to: .right,
                               of: checkBox,
                               withOffset: TaskView.titleFieldSideMargin)
        titleField.autoPinEdge(.right,
                               to: .left,
                               of: groupIcon,
                               withOffset: -TaskView.titleFieldSideMargin)
        
        titleField.autoPinEdge(toSuperviewEdge: .top, withInset: 10.5)
        titleField.autoPinEdge(toSuperviewEdge: .bottom, withInset: 11.5)
    }
    
    private static let titleFieldSideMargin: CGFloat = 8.5
    
    private lazy var titleField: TextView =
    {
        let textField = addForAutoLayout(TextView())
    
        self.observe(textField.messenger) { [weak self] in self?.didReceive($0) }
        
        return textField
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
            task?.title <- String(withNonEmpty: titleField.string)
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
        groupIcon.isEnabled = !editing
        checkBox.alphaValue = editing ? 0 : 1
        checkBox.isEnabled = !editing
        NSAnimationContext.endGrouping()
    }
    
    // MARK: - Check Box

    private func constrainCheckBox()
    {
        checkBox.autoPinEdge(toSuperviewEdge: .top, withInset: 10.5)
        checkBox.autoPinEdge(toSuperviewEdge: .left, withInset: 10.5)
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
        groupIcon.autoPinEdge(toSuperviewEdge: .top, withInset: 10.5)
        groupIcon.autoPinEdge(toSuperviewEdge: .right, withInset: 10.5)
    }
    
    private lazy var groupIcon: Icon = addForAutoLayout(Icon(with: TaskView.groupIconImage))
    
    private static let groupIconImage = #imageLiteral(resourceName: "group_indicator")
    
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
