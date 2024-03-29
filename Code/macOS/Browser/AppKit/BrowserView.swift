import AppKit
import SwiftUIToolz
import GetLaid
import SwiftObserver
import SwiftyToolz

class BrowserView: LayerBackedView, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout, Observer
{
    // MARK: - Life Cycle
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        browser.lists.forEach { pushListView(for: $0) }
        observeBrowser()
        observe(Font.baseSize) { [weak self] _ in self?.fontSizeDidChange() }
        constrainCollectionView()
    }
    
    required init?(coder decoder: NSCoder) { nil }
    
    // MARK: - Adapt to Font Size Changes
    
    private func fontSizeDidChange()
    {
        listViews.forEach { $0.fontSizeDidChange() }
    }
    
    // MARK: - Browser
    
    // TODO: do we necessarily have to do this here? can we forward these key events to the browser somewhere else? this doesn't have much to do with the view...
    
    open override func performKeyEquivalent(with event: NSEvent) -> Bool
    {
        guard event.type == .keyDown else
        {
            return super.performKeyEquivalent(with: event)
        }
        
        switch event.key
        {
        case .esc:
            if !browser.canMove(.left)
            {
                return super.performKeyEquivalent(with: event)
            }
            browser.move(.left)
        case .tab: browser.move(.right)
        case .space:
            if !reachedItemNumberLimit
            {
                browser.focusedList.create(at: 0)
            }
        default: return super.performKeyEquivalent(with: event)
        }
        
        return true
    }
    
    /////////////// TODO: Refactor/Review from here ->
    
    private func observeBrowser()
    {
        observe(browser)
        {
            [unowned self] event in self.did(receive: event)
        }
        
        observe(browser.focusedIndexVariable)
        {
            [unowned self] indexChange in
            
            self.browserDidMoveFocus(from: indexChange.old, to: indexChange.new)
        }
    }
    
    private func did(receive event: Browser.Event)
    {
        if case .didPush(let newList) = event
        {
            pushListView(for: newList)
        }
    }
    
    // MARK: - React to Window Size Changes
    
    func windowDidResize()
    {
        collectionView.collectionViewLayout?.invalidateLayout()
    }
    
    func windowDidEndResizing()
    {
        listViews.forEach { $0.didEndResizing() }
    }
    
    // MARK: - List Views
    
    private func pushListView(for list: List)
    {
        let newListView = ListView()
        
        newListView.configure(with: list)
        
        listViews.append(newListView)
        
        observe(listView: newListView)
    }
    
    private func observe(listView: ListView)
    {
        observe(listView).select(.didReceiveUserInput)
        {
            [weak listView, weak self] in
            guard let listView = listView else { return }
            self?.listViewReceivedUserInput(listView)
        }
    }
    
    private func listViewReceivedUserInput(_ listView: ListView)
    {
        guard let listIndex = listViews.firstIndex(where: { $0 === listView }) else
        {
            return log(error: "Couldn't get index of list view that received user input")
        }
        
        browser.move(to: listIndex)
    }
    
    private func browserDidMoveFocus(from: Int, to: Int)
    {
        guard listViews.isValid(index: to) else { return }
        
        move(from > to ? .left : .right)
    }
    
    private func move(_ direction: Direction)
    {
        let deleteIndex = direction == .left ? 4 : 0
        let insertIndex = direction == .left ? 0 : 4
        
        let animatedCollectionView = collectionView.animator()
        
        animatedCollectionView.performBatchUpdates(
        {
            NSAnimationContext.current.duration = 0.3
            animatedCollectionView.deleteItems(at: Set([IndexPath(item: deleteIndex,
                                                                  section: 0)]))
            animatedCollectionView.insertItems(at: Set([IndexPath(item: insertIndex,
                                                                  section: 0)]))
        })
    }
    
    ////////////////////////// Refactor/Review down to here <-
    
    private var listViews = [ListView]()
  
    // MARK: - Collection View
    
    private func constrainCollectionView()
    {
        let guide = addLayoutGuide()
        guide >> right.offset(-40)
        guide >> left
        
        collectionView >> top.offset(10)
        collectionView >> bottom
        collectionView >> centerX
        collectionView >> guide.width.at(1.666666).offset(40)
    }
    
    private lazy var collectionView: NSCollectionView =
    {
        let view = addForAutoLayout(NSCollectionView())
        view.collectionViewLayout = NSCollectionViewFlowLayout()
        view.dataSource = self
        view.delegate = self
        view.backgroundColors.removeAll()
        return view
    }()
    
    // MARK: - Collection View Data Source and Delegate
    
    func collectionView(_ collectionView: NSCollectionView,
                        numberOfItemsInSection section: Int) -> Int { 5 }
    
    func collectionView(_ collectionView: NSCollectionView,
                        itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem
    {
        // TODO: is there no way the collection view recycles item views?
        ListViewCell(listView: listViews.at(targetListIndex(atCellIndex: indexPath.item)))
    }
    
    private func targetListIndex(atCellIndex cellIndex: Int) -> Int
    {
        (cellIndex - 2) + browser.focusedIndex
    }
    
    func collectionView(_ collectionView: NSCollectionView,
                        layout collectionViewLayout: NSCollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> NSSize
    {
        NSSize(width: ((collectionView.bounds.size.width - 40) / 5.0),
               height: collectionView.bounds.size.height)
    }
    
    func collectionView(_ collectionView: NSCollectionView,
                        layout collectionViewLayout: NSCollectionViewLayout,
                        insetForSectionAt section: Int) -> NSEdgeInsets { NSEdgeInsetsZero }
    
    func collectionView(_ collectionView: NSCollectionView,
                        layout collectionViewLayout: NSCollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat { 0 }
    
    func collectionView(_ collectionView: NSCollectionView,
                        layout collectionViewLayout: NSCollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat { 10 }
    
    // MARK: - Observer
    
    let receiver = Receiver()
}
