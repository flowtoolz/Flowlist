import AppKit
import UIToolz
import SwiftObserver
import SwiftyToolz

class BrowserView: LayerBackedView, Observer
{
    // MARK: - Life Cycle
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        observe(keyboard) { [weak self] in self?.process($0) }
        
        observeBrowser()
        
        backgroundColor = Color.background
        
        createListViews()
        configureListViews()
        layoutListViews()
    }
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
    deinit { stopObserving(keyboard) }
    
    // MARK: - Keyboard Input
    
    private func process(_ keyEvent: NSEvent)
    {
        guard let list = browser.list(at: 2) else { return }
        
        //log("keyboard: \(keyEvent.key) (\(keyEvent.keyCode))")
        
        switch keyEvent.key
        {
        
        case .left: browser.move(.left)
            
        case .right: browser.move(.right)
            
        case .enter:
        
            guard !TextField.isEditing else { return }
        
            let numSelections = list.selection.count
            
            if numSelections > 0, keyEvent.cmd
            {
                if let index = list.selection.indexes.first
                {
                    listViews[2].scrollTable.tableView.editTitle(at: index)
                }
                
                break
            }
            
            if numSelections < 2
            {
                list.createBelowSelection()
            }
            else
            {
                list.groupSelectedTasks()
            }
            
        case .space: list.create(at: 0)
            
        case .delete:
            if keyEvent.cmd
            {
                list.checkOffFirstSelectedUncheckedTask()
            }
            else
            {
                _ = list.removeSelectedTasks()
            }
            
        case .down: if keyEvent.cmd { list.moveSelectedTask(1) }
            
        case .up: if keyEvent.cmd { list.moveSelectedTask(-1) }
            
        case .tab: break
            
        case .unknown:
            switch keyEvent.characters
            {
            case "t": if keyEvent.cmd { store.root.debug() }
            case "l": if keyEvent.cmd { browser.list(at: 2)?.debug() }
            default: break
            }
        }
    }
    
    // MARK: - Create and Configure List Views
    
    private func configureListViews()
    {
        for index in 0 ..< browser.numberOfLists
        {
            guard let list = browser.list(at: index),
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
        let listView = SelectableListView.newAutoLayout()
        addSubview(listView)
        
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
        
        guard let newList = browser.list(at: newListIndex) else
        {
            log(error: "Couldn't get first list from browser.")
            return
        }
        
        guard let newListView = moveListViews(direction.reverse) else { return }
        
        newListView.configure(with: newList)
        
        makeFocusedTableFirstResponder()
        
        relayoutAnimated(with: newListView)
    }
    
    private func moveListViews(_ direction: Direction) -> SelectableListView?
    {
        let left = direction == .left
        let removalIndex = left ? 0 : listViews.count - 1
        listViews.remove(at: removalIndex).removeFromSuperview()
    
        return addListView(prepend: !left)
    }
    
    private func relayoutAnimated(with addedListView: SelectableListView)
    {
        addedListView.isHidden = true
        
        NSAnimationContext.runAnimationGroup(
            {
                $0.allowsImplicitAnimation = true
                $0.duration = 0.3
                
                layoutListViews()
                layoutSubtreeIfNeeded()
            },
            completionHandler:
            {
                addedListView.isHidden = false
            }
        )
    }
    
    // MARK: - Layout List Views
    
    private func layoutListViews()
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
        guard listViews.isValid(index: 2), listViews[2].scrollTable.tableView.makeFirstResponder() else
        {
            log(error: "Could not make table view first responder.")
            return false
        }
        
        return true
    }
    
    // MARK: - Basics
    
    private var listViews = [SelectableListView]()
    
    private let browser = Browser()
}
