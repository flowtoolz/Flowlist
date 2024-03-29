import AppKit
import SwiftObserver
import SwiftyToolz
import SwiftUIToolz

class ItemTable: AnimatedTableView, SwiftObserver.ObservableObject, TableContentDelegate, Observer
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
        if #available(macOS 11.0, *) { style = .plain }
    }
    
    required init?(coder: NSCoder) { nil }
    
    // MARK: - Adapt to Font Size Changes
    
    func fontSizeDidChange()
    {
        itemHeightCash.removeAll()
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
            case .did(let edit): self?.did(edit)
            case .didChangeSelection(let addedSelections, _):
                addedSelections.first.forSome { self?.scrollAnimatedTo(row: $0) }
            }
        }
    }
    
    private func did(_ edit: Item.Event.NodeUpdate)
    {
        switch edit
        {
        case .insertedNodes(let first, let last): didInsertAtPositions(from: first, to: last)
        case .removedNodes(_, let indexes): didRemove(from: indexes)
        case .movedNode(let from, let to): didMove(from: from, to: to)
        case .switchedParent(let old, let new): didChangeRoot(from: old, to: new)
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
                didInsertAtPositions(from: 0, to: newNumber - 1)
            }
        }
    }
    
    // MARK: - Animation
    
    private func didChangeRoot(from old: Tree<ItemData>?,
                               to new: Tree<ItemData>?)
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
        insertRows(at: Array(0 ..< numberToInsertBack), firstIndex: 0)
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
    
    private func didInsertAtPositions(from firstIndex: Int, to lastIndex: Int)
    {
        // with this possibly not yet existing index it only works because we have a pseudo row at the end (rounded corners)
        
        insertRows(at: Array(firstIndex ... lastIndex), firstIndex: firstIndex)
        
        guard numberOfRows > 1, !rowIsVisible(firstIndex) else { return }

        OperationQueue.main.addOperation
        {
            self.scrollAnimatedTo(row: firstIndex)
            {
                if let itemData = self.list?[firstIndex]?.data,
                    itemData.wantsTextInput
                {
                    itemData.requestTextInput()
                }
            }
        }
    }
    
    private func insertRows(at indexes: [Int], firstIndex: Int)
    {
        insertRows(at: IndexSet(indexes), withAnimation: .slideDown)
        
        guard let list = self.list else { return }
        
        if indexes.count == 1,
            list.root?.children.isValid(index: firstIndex) ?? false,
            list[firstIndex]?.data.wantsTextInput ?? false
        {
            rowBeingEdited = firstIndex
            list.editText(at: firstIndex)
        }
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
    
    private lazy var content: ItemTableContent =
    {
        let tableContent = ItemTableContent()
        tableContent.delegate = self
        observe(tableContent) { [unowned self] in self.didReceive($0) }
        return tableContent
    }()
    
    private func didReceive(_ event: ItemTableContent.Event)
    {
        switch event
        {
        case .didCreate(let itemView): observe(itemView: itemView)
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
        guard let item = list?[row] else
        {
            return ItemView.heightWithSingleLine
        }
        
        var height = viewHeight(for: item)
        
        if row == rowBeingEdited || item.data.wantsTextInput
        {
            height += TextView.lineHeight + TextView.lineSpacing
        }
        
        return height
    }
    
    private func viewHeight(for item: Item) -> CGFloat
    {
        if let height = itemHeightCash[item] { return height }
        
        let text = item.text ?? "Untitled"
        
        let height = ItemView.preferredHeight(for: text, width: frame.size.width)
        
        itemHeightCash[item] = height
        
        return height
    }
    
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
        case .willEditText:
            if index != rowBeingEdited
            {
                rowBeingEdited = index
                noteHeightOfRows(withIndexesChanged: [index])
            }
            
            send(event)
            
        case .didChangeText:
            guard let item = itemView.item else { break }
            
            itemHeightCash[item] = nil
            noteHeightOfRows(withIndexesChanged: [index])
            
        case .wantToEndEditingText:
            NSApp.mainWindow?.makeFirstResponder(NSApp.mainWindow)
            
        case .didEditText:
            rowBeingEdited = nil
            
            guard let item = itemView.item else { break }
            
            itemHeightCash[item] = nil
            noteHeightOfRows(withIndexesChanged: [index])
            
            //editNextSelectedItem()
            
        case .wasClicked(let click):
            NSApp.mainWindow?.makeFirstResponder(NSApp.mainWindow)
            
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
        case .textViewWasClicked: list?.setSelectionWithItemsListed(at: [index])
        }
    }
    
    private func editNextSelectedItem()
    {
        guard let list = list else { return }
        
        let selected = list.selectedIndexes
        
        guard selected.count > 1 else { return }
        
        list.deselectItems(at: [selected[0]])
        
        list[selected[1]]?.edit()
    }
    
    override func mouseDown(with event: NSEvent)
    {
        send(.wasClicked(withEvent: event))
    }
    
    override var acceptsFirstResponder: Bool { true }
    
    // MARK: - Edit Texts
    
    private var rowBeingEdited: Int?
    
    // MARK: - Observable Observer
    
    let messenger = Messenger<ItemView.Event>()
    let receiver = Receiver()
}
