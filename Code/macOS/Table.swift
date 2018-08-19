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
        backgroundColor = .clear
        headerView = nil
        intercellSpacing = cellSpacing
        delegate = content
        dataSource = content
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    deinit { stopAllObserving() }
    
    // MARK: - Adapt to Font Size Changes
    
    func fontSizeDidChange()
    {
        intercellSpacing = cellSpacing
        reloadData()
    }
    
    private var cellSpacing: CGSize
    {
        return NSSize(width: 0, height: TextView.itemSpacing)
    }
    
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
        list?[index]?.isBeingEdited = true
        
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
        
        if list?.selection.isSelected(list?[to]) ?? false
        {
            scrollRowToVisible(to)
        }
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
        guard let task = list?[row] else { return TextView.itemHeight }
        
        let title = task.title.value ?? "untitled"
        
        let horizontalGap = TextView.itemSpacing
        
        let windowWidth = Window.intendedMainWindowSize.value?.width ?? 1024
        
        let tableWidth = ((windowWidth - (4 * horizontalGap)) / 3) - (2 * (horizontalGap + 1))
        
        let editingPadding = task.isBeingEdited ? TextView.lineHeight + TextView.itemLineSpacing : 0
        
        return TaskView.preferredHeight(for: title,
                                        width: tableWidth) + editingPadding
    }
    
    // MARK: - Selection
    
    func listDidChangeSelection()
    {
        if list == nil
        {
            // FIXME: why does this happen sometimes when going left?
            //log(warning: "List changed selection but list is nil.")
        }

        let listSelection = list?.selection.indexes ?? []
        let tableViewSelection = selection
        
        guard tableViewSelection != listSelection else { return }

        let rowNumber = dataSource?.numberOfRows?(in: self) ?? 0

        let listSelectionLast = listSelection.last
        
        if let last = listSelectionLast, last >= rowNumber
        {
            log(error: "List has at least one invalid selection index.")
            return
        }
        
//        // TODO: update only those rows that actually where added/removed to/from selection -> selection must send more specific infos
//        
//        for i in 0 ..< numberOfRows
//        {
//            if let view = view(atColumn: 0, row: i, makeIfNecessary: false),
//                let taskView = view as? TaskView
//            {
//                taskView.will(select: listSelection.contains(i))
//            }
//        }
        
        selectRowIndexes(IndexSet(listSelection),
                         byExtendingSelection: false)
        
        // scroll to appropriate row if selection extended
        let lastSelectionChanged = tableViewSelection.last != listSelectionLast
        let firstSelectionChanged = tableViewSelection.first != listSelection.first
        
        if lastSelectionChanged && !firstSelectionChanged,
            let last = listSelectionLast
        {
            scrollRowToVisible(last)
        }
        else if !lastSelectionChanged && firstSelectionChanged,
            let first = listSelection.first
        {
            scrollRowToVisible(first)
        }
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
        
        if let firstSelectedRow = tableSelection.first
        {
            scrollRowToVisible(firstSelectedRow)
        }
        
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
            if let task = taskView.task,
                !(list?.selection.isSelected(task) ?? false)
            {
                list?.selection.set(with: task)
            }
            
            send(event)
            noteHeightOfRows(withIndexesChanged: [index])
            
        case .didChangeTitle:
            noteHeightOfRows(withIndexesChanged: [index])
            
        case .wantToEndEditingText:
            NSApp.mainWindow?.makeFirstResponder(self)
            
        case .didEditTitle:
            noteHeightOfRows(withIndexesChanged: [index])
            //editTitleOfNextSelectedTaskView()
        }
    }
    
    // MARK: - Edit Titles
    
    private func editTitleOfNextSelectedTaskView()
    {
        guard list?.selection.count ?? 0 > 1 else
        {
            nextEditingPosition = 0
            return
        }
        
        nextEditingPosition += 1
        
        if let indexes = list?.selection.indexes,
            nextEditingPosition < indexes.count
        {
            editTitle(at: indexes[nextEditingPosition])
        }
        else
        {
            nextEditingPosition = 0
        }
        
       // list?.selection.removeTask(at: firstSelectedIndex)
    }
    
    private var nextEditingPosition: Int = 0
    
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
        
        taskView.editText()
    }
    
    // MARK: - Input

    override func keyDown(with event: NSEvent)
    {
        nextResponder?.keyDown(with: event)
    }
    
    override func mouseDown(with event: NSEvent)
    {
        super.mouseDown(with: event)
        nextResponder?.mouseDown(with: event)
    }
    
    // MARK: - Observability
    
    var latestUpdate: TaskView.Event { return .didNothing }
}
