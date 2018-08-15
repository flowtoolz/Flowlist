import AppKit
import UIToolz
import UIObserver
import SwiftObserver
import SwiftyToolz

class BrowserView: NSView, Observer
{
    // MARK: - Life Cycle
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        constrainListLayoutGuides()
        
        for index in 0 ..< browser.numberOfLists
        {
            guard let list = browser[index] else { continue }
                
            pushListView(for: list)
        }
        
        observeBrowser()
    }
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
    deinit { stopAllObserving() }
    
    // MARK: - Browser
    
    private func observeBrowser()
    {
        observe(browser)
        {
            [unowned self] event in
            
            switch event
            {
            case .didNothing: break
            
            case .didPush(let newList):
                self.pushListView(for: newList)
                
            case .didMove(let direction):
                self.browserDidMove(direction)
            }
        }
    }
    
    private func browserDidMove(_ direction: Direction)
    {
        guard makeFocusedTableFirstResponder() else { return }
        
        moveToFocusedList()
    }
    
    private let browser = Browser()
    
    // MARK: - Manage First Responder Status
    
    override var acceptsFirstResponder: Bool { return true }
    
    override func becomeFirstResponder() -> Bool
    {
        return makeFocusedTableFirstResponder()
    }
    
    @discardableResult
    private func makeFocusedTableFirstResponder() -> Bool
    {
        let index = browser.focusedListIndex
        
        guard listViews.isValid(index: index), listViews[index].scrollTable.table.makeFirstResponder() else
        {
            log(error: "Could not make table view at index \(index) first responder.")
            return false
        }
        
        return true
    }
    
    // MARK: - List Views
    
    private func pushListView(for list: SelectableList)
    {
        let newListView = addForAutoLayout(SelectableListView())
        
        newListView.configure(with: list)
        
        listViews.append(newListView)
        
        constrainLastListView()
        
        observe(listView: newListView)
    }
    
    private func observe(listView: SelectableListView)
    {
        observe(listView, select: .didReceiveUserInput)
        {
            [weak listView, weak self] in
            
            guard let listView = listView else { return }
            
            self?.listViewReceivedUserInput(listView)
        }
    }
    
    private func listViewReceivedUserInput(_ listView: SelectableListView)
    {
        guard let listIndex = listViews.index(where: { $0 === listView }) else
        {
            log(error: "Couldn't get index of list view that received user input")
            return
        }
        
        browser.focusedListIndex = listIndex
        
        moveToFocusedList()
    }
    
    // TODO: do we even need this method? why not re-use list views and just leave them hanging in memory?
    private func popListView()
    {
        guard let listView = listViews.popLast() else { return }
        
        stopObserving(listView)
        
        listView.removeFromSuperview()
    }
    
    private func constrainLastListView()
    {
        guard let listView = listViews.last else { return }
        
        let listGap = TextView.itemSpacing
        
        if listViews.count == 1
        {
            listView.autoAlignAxis(toSuperviewAxis: .vertical)
        }
        else
        {
            listView.autoPinEdge(.left,
                                 to: .right,
                                 of: listViews[listViews.count - 2],
                                 withOffset: listGap)
        }
        
        listView.autoMatch(.width, to: .width, of: listLayoutGuides[0])
        listView.autoPinEdge(toSuperviewEdge: .top, withInset: listGap)
        listView.autoPinEdge(toSuperviewEdge: .bottom, withInset: listGap)
    }
    
    func didResize()
    {
        moveToFocusedList(animated: false)
    }
    
    func didEndResizing()
    {
        for listView in listViews
        {
            listView.didEndResizing()
        }
    }
    
    private func moveToFocusedList(animated: Bool = true)
    {
        guard listViews.isValid(index: browser.focusedListIndex) else { return }
        
        let focusedListView = listViews[browser.focusedListIndex]
        let listOffset = focusedListView.frame.size.width + 2 * TextView.itemSpacing
        let targetPosition = focusedListView.frame.origin.x - listOffset
        
        if animated
        {
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current.duration = 0.3
            
            animator().bounds.origin.x = targetPosition
            
            NSAnimationContext.endGrouping()
        }
        else
        {
            bounds.origin.x = targetPosition
        }
    }
    
    private var listViews = [SelectableListView]()
    
    // MARK: - Layout Guides For List Width
    
    private func constrainListLayoutGuides()
    {
        for guide in listLayoutGuides
        {
            guide.autoPinEdge(toSuperviewEdge: .top,
                              withInset: TextView.itemSpacing)
            
            guide.autoPinEdge(toSuperviewEdge: .bottom,
                              withInset: TextView.itemSpacing)
        }
        
        listLayoutGuides[0].autoPinEdge(toSuperviewEdge: .left,
                                        withInset: TextView.itemSpacing)
        listLayoutGuides[1].autoPinEdge(.left,
                                        to: .right,
                                        of: listLayoutGuides[0],
                                        withOffset: TextView.itemSpacing)
        listLayoutGuides[1].autoMatch(.width, to: .width, of: listLayoutGuides[0])
        listLayoutGuides[2].autoPinEdge(.left,
                                        to: .right,
                                        of: listLayoutGuides[1],
                                        withOffset: TextView.itemSpacing)
        listLayoutGuides[2].autoPinEdge(toSuperviewEdge: .right,
                                        withInset: TextView.itemSpacing)
        listLayoutGuides[2].autoMatch(.width, to: .width, of: listLayoutGuides[0])
    }
    
    private lazy var listLayoutGuides: [NSView] =
    {
        let guides = [addForAutoLayout(NSView()),
                      addForAutoLayout(NSView()),
                      addForAutoLayout(NSView())]
        
        return guides
    }()
}
