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
        selectionHighlightStyle = .none
        backgroundColor = .clear
        headerView = nil
        intercellSpacing = NSZeroSize
        delegate = content
        dataSource = content
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    deinit { stopAllObserving() }
    
    // MARK: - Adapt to Font Size Changes
    
    func fontSizeDidChange()
    {
        itemHeightCash.removeAll()
        cashedWidth = nil
        reloadData()
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
    
    private func did(_ edit: Edit)
    {
        switch edit
        {
        case .nothing: break
        case .create(let index): didCreate(at: index)
        case .insert(let indexes): didInsert(at: indexes)
        case .remove(_, let indexes): didRemove(from: indexes)
        case .move(let from, let to): didMove(from: from, to: to)
        case .changeRoot(let old, let new): didChangeRoot(from: old, to: new)
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
    
    private func didChangeRoot(from old: Task?, to new: Task?)
    {
        guard isVisible else
        {
            reloadData()
            return
        }
        
        let numberToRemove = (old?.numberOfBranches ?? 0) + 1
        let numberToInsertBack = (new?.numberOfBranches ?? 0) + 1
        
        if numberToRemove == 1 && numberToInsertBack == 1 { return }
        
        didRemove(from: Array(0 ..< numberToRemove))
        didInsert(at: Array(0 ..< numberToInsertBack))
    }
    
    private var isVisible: Bool
    {
        let visibleSize = visibleRect.size
        
        return visibleSize.width > 0 && visibleSize.height > 0
    }
    
    private func didCreate(at index: Int)
    {
        rowBeingEdited = index
        
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
        removeRows(at: IndexSet(indexes), withAnimation: .slideUp)
    }
    
    private func didInsert(at indexes: [Int])
    {
        insertRows(at: IndexSet(indexes), withAnimation: .slideDown)
    }
    
    private func didMove(from: Int, to: Int)
    {
        moveRow(at: from, to: to)
        
        if list?.selection.isSelected(list?[to]) ?? false
        {
            scrollRowToVisible(to)
        }
    }
    
    // MARK: - Content
    
    var isFocused = false
    {
        didSet { content.isFocused = isFocused }
    }
    
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
        case .didNothing: break
        }
    }
    
    // MARK: - Sizing the Height
    
    func didEndResizing()
    {
        itemHeightCash.removeAll()
        
        let allIndexes = IndexSet(integersIn: 0 ..< numberOfRows)
        
        noteHeightOfRows(withIndexesChanged: allIndexes)
    }
    
    func taskViewHeight(at row: Int) -> CGFloat
    {
        guard let task = list?[row] else { return TaskView.heightWithSingleLine }
        
        var height = viewHeight(for: task)
        
        if row == rowBeingEdited
        {
            height += TextView.lineHeight + TextView.lineSpacing
        }
        
        return height
    }
    
    private func viewHeight(for task: Task) -> CGFloat
    {
        if let height = itemHeightCash[task] { return height }
        
        let title = task.title.value ?? "Untitled"
        
        let height = TaskView.preferredHeight(for: title, width: width)
        
        itemHeightCash[task] = height
        
        return height
    }
    
    private var width: CGFloat
    {
        if let cashedWidth = cashedWidth { return cashedWidth }
        
        let windowWidth = Window.intendedMainWindowSize.value?.width ?? 1024
        
        let widthForLists = windowWidth - 4 * Float.listGap.cgFloat
        
        let pixelsPerPoint = NSApp.mainWindow?.backingScaleFactor ?? 2
        
        let calculatedWidth = CGFloat(Int((pixelsPerPoint * widthForLists) / 3 + 0.5)) / pixelsPerPoint
        
        cashedWidth = calculatedWidth
        
        return calculatedWidth
    }
    
    override func layout()
    {
        super.layout()
        
        cashedWidth = frame.size.width
    }
    
    private var cashedWidth: CGFloat?
    private var itemHeightCash = [Task : CGFloat]()
    
    // MARK: - Selection
    
    func listDidChangeSelection(at indexes: [Int])
    {
        guard let list = list else
        {
            log(error: "List changed selection but list is nil.")
            return
        }
        
        var indexOf1stNewSelection: Int?
        
        for index in indexes
        {
            guard let view = view(atColumn: 0, row: index, makeIfNecessary: false),
                let taskView = view as? TaskView
            else
            {
                continue
            }
        
            let isSelected = list.selection.isSelected(taskView.task)
            
            if taskView.isSelected != isSelected
            {
                taskView.set(selected: isSelected)
                
                if indexOf1stNewSelection == nil && isSelected
                {
                    indexOf1stNewSelection = index
                }
            }
        }
        
        if let indexToScrollTo = indexOf1stNewSelection
        {
            scrollRowToVisible(indexToScrollTo)
        }
    }
    
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
            rowBeingEdited = index
            
            if let task = taskView.task,
                !(list?.selection.isSelected(task) ?? false)
            {
                list?.selection.set(with: task)
            }
            
            send(event)
            noteHeightOfRows(withIndexesChanged: [index])
            
        case .didChangeTitle:
            guard let task = taskView.task else { break }
            
            itemHeightCash[task] = nil
            noteHeightOfRows(withIndexesChanged: [index])
            
        case .wantToEndEditingText:
            NSApp.mainWindow?.makeFirstResponder(self)
            
        case .didEditTitle:
            rowBeingEdited = nil
            
            guard let task = taskView.task else { break }
            
            itemHeightCash[task] = nil
            noteHeightOfRows(withIndexesChanged: [index])
            
            //editTitleOfNextSelectedTaskView()
            
        case .wasClicked(let cmdKeyIsDown):
            NSApp.mainWindow?.makeFirstResponder(self)
            
            guard let task = taskView.task, let list = list else { break }
            
            if cmdKeyIsDown
            {
                list.selection.toggle(task)
            }
            else
            {
                list.selection.set(with: task)
            }
            
            send(event)
        }
    }
    
    override func mouseDown(with event: NSEvent)
    {
        send(.wasClicked(withCmd: false))
    }
    
    override var acceptsFirstResponder: Bool { return true }
    
    // MARK: - Edit Titles
    
    private var rowBeingEdited: Int?
    
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
    
    // MARK: - Observability
    
    var latestUpdate: TaskView.Event { return .didNothing }
}
