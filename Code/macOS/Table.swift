import AppKit
import SwiftObserver

class Table: NSTableView, Observer, Observable
{
    // MARK: - Life Cycle
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        addTableColumn(NSTableColumn(identifier: TaskView.uiIdentifier))
    
        allowsMultipleSelection = true
        backgroundColor = NSColor.clear
        headerView = nil
        intercellSpacing = NSSize(width: 0,
                                  height: Float.verticalGap.cgFloat)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Configuration
    
    func configure(with list: SelectableList)
    {
        stopObserving(self.list)
        
        observe(list)
        {
            [weak self] event in
            
            self?.didReceive(event)
        }
        
        self.list = list
    }
    
    // MARK: - Process List Events
    
    private func didReceive(_ edit: ListEdit)
    {
        //Swift.print("list view <\(titleField.stringValue)> \(change)")
        
        switch edit
        {
        case .didInsert(let indexes):
            didInsertSubtask(at: indexes)
            
        case .didRemove(_, let indexes):
            didDeleteSubtasks(at: indexes)
            
        case .didMove(let from, let to):
            didMoveSubtask(from: from, to: to)
            
        case .didNothing: break
        }
    }
    
    private func didDeleteSubtasks(at indexes: [Int])
    {
        beginUpdates()
        removeRows(at: IndexSet(indexes), withAnimation: .slideUp)
        endUpdates()
    }
    
    private func didInsertSubtask(at indexes: [Int])
    {
        beginUpdates()
        insertRows(at: IndexSet(indexes), withAnimation: .slideDown)
        endUpdates()
    }
    
    private func didMoveSubtask(from: Int, to: Int)
    {
        beginUpdates()
        moveRow(at: from, to: to)
        endUpdates()
    }
    
    // MARK: - Keyboard Input
    
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
    
    // MARK: - Mouse Input
    
    override func mouseDown(with event: NSEvent)
    {
        super.mouseDown(with: event)
        nextResponder?.mouseDown(with: event)
    }
    
    // MARK: - List
    
    private(set) weak var list: SelectableList?
    
    // MARK: - Observability
    
    var latestUpdate: NavigationRequest { return .wantsNothing }
    
    enum NavigationRequest
    {
        case wantsNothing
        case wantsToPassFocusRight
        case wantsToPassFocusLeft
        case wantsFocus
    }
}
