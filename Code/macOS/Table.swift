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

        addTableColumn(NSTableColumn(identifier: ItemView.uiIdentifier))
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
    
    func configure(with list: List)
    {
        observe(list: self.list, start: false)
        observe(list: list)
        
        self.list = list
    }
    
    private func observe(list: List?, start: Bool = true)
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
            return
        }
        
        observe(list)
        {
            [weak self] event in
            
            switch event
            {
            case .didNothing: break
            case .did(let edit): self?.did(edit)
            case .didChangeSelection(let added, _):
                if let firstSelectedIndex = added.first
                {
                    self?.scrollAnimatedTo(row: firstSelectedIndex)
                }
            }
        }
    }
    
    private func did(_ edit: Item.Edit)
    {
        switch edit
        {
        case .nothing: break
        case .insert(let indexes): didInsert(at: indexes)
        case .remove(_, let indexes): didRemove(from: indexes)
        case .move(let from, let to): didMove(from: from, to: to)
        case .changeRoot(let old, let new): didChangeRoot(from: old, to: new)
        }
    }
    
    private weak var list: List?
    {
        didSet
        {
            guard oldValue !== list else
            {
                log(warning: "Tried to set identical list")
                return
            }
            
            content.configure(with: list)
            
            if let oldNumber = oldValue?.count, oldNumber > 0
            {
                didRemove(from: Array(0 ..< oldNumber))
            }
            
            if let newNumber = list?.count, newNumber > 0
            {
                didInsert(at: Array(0 ..< newNumber))
            }
        }
    }
    
    // MARK: - Animation
    
    private func didChangeRoot(from old: Item?,
                               to new: Item?)
    {
        guard isVisible else
        {
            reloadData()
            return
        }
        
        let numberToRemove = (old?.count ?? 0) + 1
        let numberToInsertBack = (new?.count ?? 0) + 1
        
        if numberToRemove == 1 && numberToInsertBack == 1 { return }
        
        didRemove(from: Array(0 ..< numberToRemove))
        didInsert(at: Array(0 ..< numberToInsertBack))
    }
    
    private var isVisible: Bool
    {
        let visibleSize = visibleRect.size
        
        return visibleSize.width > 0 && visibleSize.height > 0
    }
    
    private func didRemove(from indexes: [Int])
    {
        removeRows(at: IndexSet(indexes), withAnimation: .slideUp)
    }
    
    private func didInsert(at indexes: [Int])
    {
        insertRows(at: IndexSet(indexes), withAnimation: .slideDown)
        
//        if indexes.count == 1, let index = indexes.first
//        {
//            OperationQueue.main.addOperation
//            {
//                self.scrollAnimatedTo(row: index) {}
//            }
//        }
    }
    
    private func didMove(from: Int, to: Int)
    {
        moveRow(at: from, to: to)
        
        if list?[to]?.isSelected ?? false
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
        case .didCreate(let itemView): observe(itemView: itemView)
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
    
    func itemViewHeight(at row: Int) -> CGFloat
    {
        guard let item = list?[row] else { return ItemView.heightWithSingleLine }
        
        var height = viewHeight(for: item)
        
        if row == rowBeingEdited
        {
            height += TextView.lineHeight + TextView.lineSpacing
        }
        
        return height
    }
    
    private func viewHeight(for item: Item) -> CGFloat
    {
        if let height = itemHeightCash[item] { return height }
        
        let title = item.title ?? "Untitled"
        
        let height = ItemView.preferredHeight(for: title, width: width)
        
        itemHeightCash[item] = height
        
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
    private var itemHeightCash = [Item : CGFloat]()
    
    // MARK: - Observe Item Views
    
    private func observe(itemView: ItemView)
    {
        observe(itemView)
        {
            [weak self, weak itemView] event in
            
            guard let itemView = itemView else { return }
            
            self?.didReceive(event, from: itemView)
        }
    }
    
    private func didReceive(_ event: ItemView.Event, from itemView: ItemView)
    {
        let index = row(for: itemView)
        
        guard index >= 0 else { return }
        
        switch event
        {
        case .didNothing: break
            
        case .willEditTitle:
            rowBeingEdited = index
            
            if !(list?[index]?.isSelected ?? false)
            {
                list?.setSelectionWithItemsListed(at: [index])
            }
            
            send(event)
            
            noteHeightOfRows(withIndexesChanged: [index])
            
        case .didChangeTitle:
            guard let item = itemView.item else { break }
            
            itemHeightCash[item] = nil
            noteHeightOfRows(withIndexesChanged: [index])
            
        case .wantToEndEditingText:
            NSApp.mainWindow?.makeFirstResponder(self)
            
        case .didEditTitle:
            rowBeingEdited = nil
            
            guard let item = itemView.item else { break }
            
            itemHeightCash[item] = nil
            noteHeightOfRows(withIndexesChanged: [index])
            
        case .wasClicked(let click):
            NSApp.mainWindow?.makeFirstResponder(self)
            
            guard let list = list else { break }
            
            if click.cmd
            {
                list.toggleSelection(at: index)
            }
            else if click.shift
            {
                list.extendSelection(to: index)
            }
            else
            {
                list.setSelectionWithItemsListed(at: [index])
            }
            
            send(event)
        }
    }
    
    override func mouseDown(with event: NSEvent)
    {
        send(.wasClicked(withEvent: event))
    }
    
    override var acceptsFirstResponder: Bool { return true }
    
    // MARK: - Edit Titles
    
    private var rowBeingEdited: Int?
    
    // MARK: - Observability
    
    var latestUpdate = ItemView.Event.didNothing
}
