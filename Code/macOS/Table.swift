import AppKit
import SwiftObserver
import SwiftyToolz
import UIToolz

class Table: AnimatedTableView, Observer, Observable, TableContentDelegate
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
        case .create(let index): didCreate(at: index)
        case .insert(let indexes): didInsert(at: indexes)
        case .remove(_, let indexes): didRemove(from: indexes)
        case .move(let from, let to): didMove(from: from, to: to)
        case .nothing, .changeRoot: break
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
        
        tableContent.delegate = self
        
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
    
    // MARK: - Sizing the Height
    
    func didEndResizing()
    {
        let allIndexes = IndexSet(integersIn: 0 ..< numberOfRows)
        
        noteHeightOfRows(withIndexesChanged: allIndexes)
    }
    
    func taskViewHeight(at row: Int) -> CGFloat
    {
        guard let task = list?[row] else { return Float.itemHeight.cgFloat }
        
        let title = task.title.value ?? "untitled"
        
        let horizontalGap: CGFloat = 10
        let tableWidth = (Table.windowWidth - (4 * horizontalGap)) / 3
        
        let editingPadding = task.isBeingEdited ? TextField.heightOfOneLine : 0
        
        return TaskView.preferredHeight(for: title,
                                        width: tableWidth) + editingPadding
    }
    
    static var windowWidth: CGFloat = 0
    
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
            
            guard let taskView = taskView else { return }
            
            self?.didReceive(event, from: taskView)
        }
    }
    
    private func didReceive(_ event: TaskView.Event, from taskView: TaskView)
    {
        let index = row(for: taskView)
        
        guard index >= 0 else { return }
        
        switch event
        {
        case .didNothing: break
            
        case .willEditTitle:
            send(event)
            noteHeightOfRows(withIndexesChanged: [index])
            
        case .didChangeTitle:
            noteHeightOfRows(withIndexesChanged: [index])
            
        case .didEditTitle:
            noteHeightOfRows(withIndexesChanged: [index])
            editTitleOfNextSelectedTaskView()
        }
    }
    
    // MARK: - Edit Titles
    
    private func editTitleOfNextSelectedTaskView()
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
    
    private func editTitle(at index: Int)
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
