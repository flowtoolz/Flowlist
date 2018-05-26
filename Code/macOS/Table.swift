import AppKit
import SwiftObserver
import SwiftyToolz

class Table: AnimatedTableView, Observer
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
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    deinit { stopAllObserving() }
    
    // MARK: - Selection
    
    func selectionDidChange()
    {
        let selectedIndexes = Array(selectedRowIndexes)
        
        list?.selection.setWithTasksListed(at: selectedIndexes)
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
            log(warning: "Tried to \(start ? "start" : "stop") observing nil list.")
            stopObservingDeadObservables()
            return
        }
        
        guard start else
        {
            stopObserving(list)
            stopObserving(list.selection)
            return
        }
        
        observe(list) { [weak self] edit in self?.did(edit) }
        
        observe(list.selection, select: .didChange)
        {
            [weak self, weak list] in
            
            guard let list = list else
            {
                log(error: "Received selection update from dead list.")
                self?.stopObservingDeadObservables()
                return
            }
            
            self?.selectionChanged(in: list)
        }
    }
    
    private func selectionChanged(in list: SelectableList)
    {
        let listSelection = list.selection.indexes
        
        guard listSelection.last ?? 0 < numberOfRows else { return }
        
        let tableSelection = Array(selectedRowIndexes).sorted()
        
        guard tableSelection != listSelection else { return }
        
        selectRowIndexes(IndexSet(listSelection), byExtendingSelection: false)
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
    
    private func did(_ edit: ListEdit)
    {
        //Swift.print("list view <\(titleField.stringValue)> \(change)")
        
        switch edit
        {
        case .didCreate(let index): didCreate(at: index)
        case .didInsert(let indexes): didInsert(at: indexes)
        case .didRemove(_, let indexes): didRemove(from: indexes)
        case .didMove(let from, let to): didMove(from: from, to: to)
        case .didNothing: break
        }
    }
    
    private func didCreate(at index: Int)
    {
        CATransaction.begin()
        CATransaction.setCompletionBlock
        {
            self.editTitle(at: index)
        }
        
        self.didInsert(at: [index])
        
        CATransaction.commit()
        
        scrollAnimatedTo(row: min(numberOfRows - 1, index))
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
    
    override var acceptsFirstResponder: Bool { return true }
    
    override func keyDown(with event: NSEvent)
    {
        if forward(keyEvent: event)
        {
            nextResponder?.keyDown(with: event)
        }
        else
        {
            super.keyDown(with: event)
        }
    }
    
    private func forward(keyEvent event: NSEvent) -> Bool
    {
        switch event.key
        {
        case .enter: return true
        case .down, .up: return event.cmd
        default: return false
        }
    }
    
    override func mouseDown(with event: NSEvent)
    {
        super.mouseDown(with: event)
        nextResponder?.mouseDown(with: event)
    }
}
