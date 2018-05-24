import AppKit
import SwiftObserver

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
    
    func loadSelectionFromList()
    {
        let selection = list?.selection.indexes ?? []
        
        guard selection.max() ?? 0 < numberOfRows else { return }
        
        selectRowIndexes(IndexSet(selection), byExtendingSelection: false)
    }
    
    func saveSelectionToList()
    {
        let selectedIndexes = Array(selectedRowIndexes)
        
        list?.selection.setWithTasksListed(at: selectedIndexes)
    }
    
    // MARK: - Configuration
    
    func configure(with list: SelectableList)
    {
        stopObserving(self.list)
        observe(list) { [weak self] edit in self?.did(edit) }
        
        self.list = list
    }
    
    private weak var list: SelectableList?
    
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
