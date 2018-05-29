import AppKit
import SwiftObserver
import SwiftyToolz
import UIToolz

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
    
    // MARK: - Configuration & Selection
    
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
    
    func selectionDidChange()
    {
        let tableSelection = selection
        
        guard tableSelection != listSelection else { return }
        
        list?.selection.setWithTasksListed(at: tableSelection)
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
            
            selectionChanged(in: list)
            
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
    
    private func selectionChanged(in list: SelectableList?)
    {
        let listSelection = self.listSelection
        
        guard selection != listSelection else { return }
        
        let rowNumber = dataSource?.numberOfRows?(in: self) ?? 0
        
        if let last = listSelection.last, last >= rowNumber
        {
            log(error: "List has at least one invalid selection index.")
            return
        }
        
        selectRowIndexes(IndexSet(listSelection), byExtendingSelection: false)
    }
    
    private var selection: [Int] { return Array(selectedRowIndexes).sorted() }
    private var listSelection: [Int] { return list?.selection.indexes ?? [] }
    
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
}
