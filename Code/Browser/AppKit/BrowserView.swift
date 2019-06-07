import AppKit
import UIToolz
import UIObserver
import SwiftObserver
import SwiftyToolz

class BrowserView: LayerBackedView, Observer, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout
{
    // MARK: - Life Cycle
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        for index in 0 ..< browser.numberOfLists
        {
            guard let list = browser[index] else { continue }
            
            pushListView(for: list)
        }
        
        observeBrowser()
        
        observe(Font.baseSize)
        {
            [weak self] _ in self?.fontSizeDidChange()
        }
        
        initializeCollectionView()
    }
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
    deinit { stopObserving() }
    
    // MARK: - Adapt to Font Size Changes
    
    private func fontSizeDidChange()
    {
        listViews.forEach { $0.fontSizeDidChange() }
    }
    
    // MARK: - Browser
    
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
    
    private func observeBrowser()
    {
        observe(browser)
        {
            [unowned self] event in self.did(receive: event)
        }
        
        observe(browser.focusedIndexVariable)
        {
            [unowned self] indexUpdate in
            
            self.moveToFocusedList(from: indexUpdate.old,
                                   to: indexUpdate.new,
                                   animated: true)
        }
    }
    
    private func did(receive event: Browser.Event)
    {
        if case .didPush(let newList) = event
        {
            pushListView(for: newList)
        }
    }
    
    // MARK: - Resizing
    
    func didResize()
    {
        collectionView.collectionViewLayout?.invalidateLayout()
    }
    
    func didEndResizing()
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
            log(error: "Couldn't get index of list view that received user input")
            return
        }
        
        browser.move(to: listIndex)
    }
    
    private func moveToFocusedList(from: Int? = nil,
                                   to: Int? = nil,
                                   animated: Bool = true)
    {
        let toIndex = to ?? browser.focusedIndex
        
        guard listViews.isValid(index: toIndex),
            let fromIndex = from else { return }
        
        if fromIndex > toIndex
        {
            self.collectionView.animator().performBatchUpdates({
                self.collectionView.deleteItems(at: Set([IndexPath(item: 4, section: 0)]))
                self.collectionView.insertItems(at: Set([IndexPath(item: 0, section: 0)]))
            }, completionHandler: nil)
        }
        else
        {
            self.collectionView.animator().performBatchUpdates({
                self.collectionView.deleteItems(at: Set([IndexPath(item: 0, section: 0)]))
                self.collectionView.insertItems(at: Set([IndexPath(item: 4, section: 0)]))
            }, completionHandler: nil)
        }
    }
    
    private var listViews = [ListView]()
    
    // MARK: - Collection View
    
    private func initializeCollectionView() {
        let guide = addLayoutGuide()
        guide.constrainRight(to: self, offset: -40)
        guide.constrainLeft(to: self)
        
        collectionView.constrainTopToParent(inset: 10)
        collectionView.constrainBottomToParent()
        collectionView.constrainCenterXToParent()
        collectionView.widthAnchor.constraint(equalTo: guide.widthAnchor,
                                              multiplier: 1.66666,
                                              constant: 40).isActive = true
        collectionView.collectionViewLayout = NSCollectionViewFlowLayout()
        collectionView.register(ListViewCell.self,
                                forItemWithIdentifier: NSUserInterfaceItemIdentifier("TestCollectionViewID"))
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColors.removeAll()
    }
    
    private lazy var collectionView = addForAutoLayout(NSCollectionView())
    
    // MARK: - Collection View Data Source and Delegate
    
    func collectionView(_ collectionView: NSCollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return 5
    }
    
    func collectionView(_ collectionView: NSCollectionView,
                        itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        
        let listIndex = (indexPath.item - 2) + browser.focusedIndex
        
        guard listViews.isValid(index: listIndex) else
        {
            log(error: "list index \(listIndex) is invalid. We have \(listViews.count) list views.")
            return ListViewCell(listView: nil)
        }
        
        return ListViewCell(listView: listViews[listIndex])
    }
    
    func collectionView(_ collectionView: NSCollectionView,
                        layout collectionViewLayout: NSCollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> NSSize {
        return NSSize(width: ((collectionView.bounds.size.width - 40) / 5.0),
                      height: collectionView.bounds.size.height)
    }
    
    func collectionView(_ collectionView: NSCollectionView,
                        layout collectionViewLayout: NSCollectionViewLayout,
                        insetForSectionAt section: Int) -> NSEdgeInsets {
        return NSEdgeInsetsZero
    }
    
    func collectionView(_ collectionView: NSCollectionView,
                        layout collectionViewLayout: NSCollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: NSCollectionView,
                        layout collectionViewLayout: NSCollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
}
