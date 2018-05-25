import AppKit
import SwiftObserver
import SwiftyToolz

class Table: NSTableView, Observer
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
        stopObserving(self.list)
        observe(list) { [weak self] edit in self?.did(edit) }
        
        stopObserving(self.list?.selection)
        observe(list.selection, select: .didChange)
        {
            [weak self, weak list] in
            
            guard let list = list else { return }
            
            self?.selectionChanged(in: list)
        }
        
        self.list = list
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
                log(warning: "Tried to set identical list.")
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
        case .didInsert(let indexes): didInsert(at: indexes)
        case .didRemove(_, let indexes): didRemove(from: indexes)
        case .didMove(let from, let to): didMove(from: from, to: to)
        case .didNothing: break
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
