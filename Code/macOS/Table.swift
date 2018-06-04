import AppKit
import SwiftObserver
import SwiftyToolz
import UIToolz

class Table: AnimatedTableView, Observer, Observable
{
    // MARK: - Life Cycle
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)

        addTableColumn(NSTableColumn(identifier: TaskView.uiIdentifier))
        allowsMultipleSelection = true
        backgroundColor = NSColor.clear
        headerView = nil
        intercellSpacing = NSSize(width: 0, height: Float.verticalGap.cgFloat)
        
        delegate = content
        dataSource = content
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    deinit { stopAllObserving() }
    
    // MARK: - Configuration
    
    func configure(with list: SelectableList)
    {
        observe(list: self.list, start: false)
        observe(list: list)
        
        self.list = list
    }
    
    private func observe(list: SelectableList?, start: Bool = true)
    {
        guard let list = list else
        {
            if start { log(error: "Tried to observe nil list.") }
            stopObservingDeadObservables()
            return
        }
        
        guard start else
        {
            stopObserving(list)
            stopObserving(list.selection)
            return
        }
        
        observe(list)
        {
            [weak self] event in
            
            switch event
            {
            case .didNothing: break
            case .did(let edit): self?.did(edit)
            case .wantToEditTitle(let index): self?.editTitle(at: index)
            }
        }
        
        observe(list.selection, select: .didChange)
        {
            [weak self] in self?.listDidChangeSelection()
        }
    }
    
    private weak var list: SelectableList?
    {
        didSet
        {
            guard oldValue !== list else
            {
                log(warning: "Tried to set identical list:\n\(list?.description ?? "nil")")
                return
            }
            
            content.configure(with: list)
            listDidChangeSelection()
            
            if let oldNumber = oldValue?.numberOfTasks, oldNumber > 0
            {
                didRemove(from: Array(0 ..< oldNumber))
            }
            
            if let newNumber = list?.numberOfTasks, newNumber > 0
            {
                didInsert(at: Array(0 ..< newNumber))
            }
        }
    }
    
    // MARK: - Animation
    
    private func did(_ edit: Edit)
    {
        switch edit
        {
        case .didCreate(let index): didCreate(at: index)
        case .didInsert(let indexes): didInsert(at: indexes)
        case .didRemove(_, let indexes): didRemove(from: indexes)
        case .didMove(let from, let to): didMove(from: from, to: to)
        case .didNothing, .didChangeRoot: break
            // TODO: consider processing .didChangeRoot here
        }
    }
    
    private func didCreate(at index: Int)
    {
        didInsert(at: [index])
        
        OperationQueue.main.addOperation
        {
            self.scrollAnimatedTo(row: index)
            {
                self.editTitle(at: index)
            }
        }
    }
    
    private func didRemove(from indexes: [Int])
    {
        beginUpdates()
        removeRows(at: IndexSet(indexes), withAnimation: .slideUp)
        endUpdates()
    }
    
    private func didInsert(at indexes: [Int])
    {
        beginUpdates()
        insertRows(at: IndexSet(indexes), withAnimation: .slideDown)
        endUpdates()
    }
    
    private func didMove(from: Int, to: Int)
    {
        beginUpdates()
        moveRow(at: from, to: to)
        endUpdates()
    }
    
    // MARK: - Content
    
    private lazy var content: TableContent =
    {
        let tableContent = TableContent()
        
        observe(tableContent) { [unowned self] in self.didReceive($0) }
        
        return tableContent
    }()
    
    private func didReceive(_ event: TableContent.Event)
    {
        switch event
        {
        case .didCreate(let taskView): observe(taskView: taskView)
        case .selectionDidChange: didChangeSelection()
        case .didNothing: break
        }
    }
    
    // MARK: - Selection
    
    private func listDidChangeSelection()
    {
        if list == nil
        {
            // FIXME: why does this happen sometimes when going left?
            //log(warning: "List changed selection but list is nil.")
        }
        
        let listSelection = list?.selection.indexes ?? []
        
        guard selection != listSelection else { return }
        
        let rowNumber = dataSource?.numberOfRows?(in: self) ?? 0
        
        if let last = listSelection.last, last >= rowNumber
        {
            log(error: "List has at least one invalid selection index.")
            return
        }
        
        selectRowIndexes(IndexSet(listSelection), byExtendingSelection: false)
    }
    
    private func didChangeSelection()
    {
        guard let list = list else
        {
            // FIXME: why does this happen sometimes when going left?
            //log(warning: "Selection changed and list is nil.")
            return
        }
        
        let tableSelection = selection
        let listSelection = list.selection.indexes
        
        guard tableSelection != listSelection else { return }
        
        list.selection.setWithTasksListed(at: tableSelection)
    }
    
    private var selection: [Int] { return Array(selectedRowIndexes).sorted() }
    
    // MARK: - Observe Task Views
    
    private func observe(taskView: TaskView)
    {
        observe(taskView)
        {
            [weak self, weak taskView] event in
            
            self?.didReceive(event, from: taskView)
        }
    }
    
    private func didReceive(_ event: TaskView.Event,
                            from taskView: TaskView?)
    {
        switch event
        {
        case .didNothing: break
        case .didEditTitle: editTitleOfNextSelectedTaskView()
        case .willEditTitle: send(event)
        case .willDeinit: stopObserving(taskView)
        }
    }
    
    // MARK: - Edit Titles
    
    func editTitleOfNextSelectedTaskView()
    {
        guard list?.selection.count ?? 0 > 1,
            let firstSelectedIndex = list?.selection.indexes.first else
        {
            return
        }
        
        list?.selection.removeTask(at: firstSelectedIndex)
        
        if let nextEditingIndex = list?.selection.indexes.first
        {
            editTitle(at: nextEditingIndex)
        }
    }
    
    func editTitle(at index: Int)
    {
        guard index < numberOfRows else
        {
            log(warning: "Tried to edit task title at invalid row \(index)")
            return
        }
        
        guard let taskView = view(atColumn: 0,
                                  row: index,
                                  makeIfNecessary: false) as? TaskView else
        {
            log(warning: "Couldn't get task view at row \(index)")
            return
        }
        
        taskView.editTitle()
    }
    
    // MARK: - Input

    override func keyDown(with event: NSEvent)
    {
        let key = event.key
        let useDefaultBehaviour = (key == .up || key == .down) && !event.cmd

        if useDefaultBehaviour
        {
            super.keyDown(with: event)
        }
        else
        {
            nextResponder?.keyDown(with: event)
        }
    }
    
    override func mouseDown(with event: NSEvent)
    {
        super.mouseDown(with: event)
        nextResponder?.mouseDown(with: event)
    }
    
    // MARK: - Observability
    
    var latestUpdate: TaskView.Event { return .didNothing }
}
