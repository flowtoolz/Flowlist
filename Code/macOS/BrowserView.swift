import AppKit
import UIToolz
import UIObserver
import SwiftObserver
import SwiftyToolz

class BrowserView: LayerBackedView, Observer
{
    // MARK: - Life Cycle
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)

        observeBrowser()
        
        backgroundColor = Color.background
        
        createListViews()
        configureListViews()
        constrainListViews()
    }
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
    deinit { stopAllObserving() }
    
    // MARK: - Create and Configure List Views
    
    private func configureListViews()
    {
        for index in 0 ..< browser.numberOfLists
        {
            guard let list = browser[index],
                listViews.isValid(index: index)
            else
            {
                log(error: "Couldn't find list or list view at index \(index).")
                continue
            }
            
            listViews[index].configure(with: list)
        }
    }
    
    private func createListViews()
    {
        listViews.removeAll()
        
        for _ in 0 ..< browser.numberOfLists { addListView() }
    }
    
    @discardableResult
    private func addListView(prepend: Bool = false) -> SelectableListView
    {
        let listView = addForAutoLayout(SelectableListView())
        
        listViews.insert(listView, at: prepend ? 0 : listViews.count)
        
        observe(listView: listView)
        
        return listView
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
        switch listViews.index(where: { $0 === listView })
        {
        case 1: browser.move(.left)
        case 3: browser.move(.right)
        default: break
        }
    }
    
    // MARK: - React to Browser
    
    private func observeBrowser()
    {
        observe(browser)
        {
            [unowned self] event in
            
            if case .didMove(let direction) = event
            {
                self.browserDidMove(direction)
            }
        }
    }
    
    private func browserDidMove(_ direction: Direction)
    {
        let movedLeft = direction == .left
        let newListIndex = movedLeft ? 0 : browser.numberOfLists - 1
        
        guard let newList = browser[newListIndex] else
        {
            log(error: "Couldn't get new list from browser.")
            return
        }
        
        let newListView = moveListViews(direction.reverse)
        
        newListView.configure(with: newList)
        
        makeFocusedTableFirstResponder()
        
        relayoutAnimated(with: newListView, direction: direction)
    }
    
    private func moveListViews(_ direction: Direction) -> SelectableListView
    {
        let left = direction == .left
    
        removeListView(at: left ? 0 : listViews.count - 1)
        
        return addListView(prepend: !left)
    }
    
    private func relayoutAnimated(with addedView: SelectableListView,
                                  direction: Direction)
    {
        let moveLeft = direction == .left
        
        addedView.frame.origin.x = frame.size.width * (moveLeft ? -1.3333 : 2)
        addedView.frame.origin.y = 0
        addedView.frame.size.height = frame.size.height
        addedView.frame.size.width = frame.size.width / 3
        
        NSAnimationContext.beginGrouping()
        
        let context = NSAnimationContext.current
        context.allowsImplicitAnimation = true
        context.duration = 0.3
        
        constrainListViews()
        layoutSubtreeIfNeeded()
        
        NSAnimationContext.endGrouping()
    }
    
    // MARK: - Layout List Views
    
    private func constrainListViews()
    {
        removeConstraints(listViewContraints)
        listViewContraints.removeAll()
        
        for i in 0 ..< listViews.count
        {
            let listView = listViews[i]
            
            if i == 0
            {
                constrain(listView.autoPinEdge(.right,
                                               to: .left,
                                               of: self))
            }
            else
            {
                constrain(listView.autoPinEdge(.left,
                                               to: .right,
                                               of: listViews[i - 1],
                                               withOffset: 10))
                
                constrain(listView.autoConstrainAttribute(.width,
                                                          to: .width,
                                                          of: listViews[i - 1]))
            }
            
            if i == listViews.count - 1
            {
                constrain(listView.autoPinEdge(.left, to: .right, of: self))
            }
            
            constrain(listView.autoPinEdge(toSuperviewEdge: .top))
            constrain(listView.autoPinEdge(toSuperviewEdge: .bottom))
        }
    }
    
    private func constrain(_ constraint: NSLayoutConstraint)
    {
        listViewContraints.append(constraint)
    }
    
    private var listViewContraints = [NSLayoutConstraint]()
    
    // MARK: - Manage First Responder Status
    
    override var acceptsFirstResponder: Bool { return true }
    
    override func becomeFirstResponder() -> Bool
    {
        return makeFocusedTableFirstResponder()
    }
    
    @discardableResult
    private func makeFocusedTableFirstResponder() -> Bool
    {
        guard listViews.isValid(index: 2), listViews[2].scrollTable.table.makeFirstResponder() else
        {
            log(error: "Could not make table view first responder.")
            return false
        }
        
        return true
    }
    
    // MARK: - Basics
    
    private func removeListView(at index: Int)
    {
        guard listViews.isValid(index: index) else { return }
        
        let removedListView = listViews.remove(at: index)
        stopObserving(removedListView)
        removedListView.removeFromSuperview()
    }
    
    private var listViews = [SelectableListView]()
    
    private let browser = Browser()
}
