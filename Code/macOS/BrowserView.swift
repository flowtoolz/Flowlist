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
        
        case .left: passFocusLeft()
            
        case .right: passFocusRight()
            
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
            if keyEvent.characters == "t" && keyEvent.cmd
            {
                store.root.debug()
            }
        }
    }
    
    // MARK: - Create and Configure List Views
    
    func configureListViews()
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
        
        if listViews.count > 2 { focusList(at: 2) }
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
    
    // MARK: - Observe List Views
    
    private func observe(listView: SelectableListView)
    {
        observe(listView, select: .didReceiveUserInput)
        {
            [weak listView, weak self] in
            
            guard let listView = listView else { return }
            
            self?.navigateTo(listView)
        }
    }
    
    // MARK: - Control Browser
    
    private func passFocusRight()
    {
        let listView = listViews[2]
        
        guard let index = listViews.index(where: { $0 === listView }),
            index >= 0, index < listViews.count - 1,
            (listView.list?.numberOfTasks ?? 0) > 0 else { return }
        
        focusList(at: index + 1)
    }
    
    private func passFocusLeft()
    {
        let listView = listViews[2]
        
        guard let index = listViews.index(where: { $0 === listView }) else
        {
            return
        }
        
        focusList(at: index - 1)
    }
    
    @discardableResult
    private func focusList(at index: Int) -> Bool
    {
        guard listViews.isValid(index: index) else { return false }
        
        let listView = listViews[index]
        
        guard listView.list?.root != nil else { return false }
        
        if let firstTask = listView.list?.task(at: 0),
            listView.list?.selection.count == 0
        {
            listView.list?.selection.add(task: firstTask)
        }
        
        guard listView.scrollTable.tableView.makeFirstResponder() else
        {
            log(warning: "Could not make table view first responder.")
            return false
        }
        
        navigateToList(at: index)
        
        return true
    }
    
    private func navigateTo(_ listView: SelectableListView)
    {
        guard let index = listViews.index(where: { $0 === listView }) else
        {
            return
        }
        
        navigateToList(at: index)
    }
    
    private func navigateToList(at index: Int)
    {
        let moveRight = index > 2
        let moveLeft = index < 2
        
        guard moveLeft || moveRight else { return }
        
        let newIndex = moveRight ? 3 : 1
        
        guard let list = browser.list(at: newIndex), list.root != nil else { return }
        
        if moveRight { browser.moveRight() } else { browser.moveLeft() }
    }
    
    // MARK: - React to Browser
    
    private func observeBrowser()
    {
        observe(browser)
        {
            [unowned self] event in
            
            switch event
            {
            case .didNothing: break
            case .didMoveLeft: self.browserDidMoveLeft()
            case .didMoveRight: self.browserDidMoveRight()
            }
        }
    }
    
    private func browserDidMoveRight()
    {
        guard let newRightList = browser.list(at: browser.numberOfLists - 1) else
        {
            log(error: "Couldn't get last list from browser.")
            return
        }
        
        guard let newRightListView = moveListViews(by: -1) else { return }
        
        newRightListView.configure(with: newRightList)
        
        relayoutAnimated(with: newRightListView)
    }
    
    private func browserDidMoveLeft()
    {
        guard let newLeftList = browser.list(at: 0) else
        {
            log(error: "Couldn't get first list from browser.")
            return
        }
        
        guard let newLeftListView = moveListViews(by: 1) else { return }
        
        newLeftListView.configure(with: newLeftList)
        
        relayoutAnimated(with: newLeftListView)
    }
    
    private func moveListViews(by positions: Int) -> SelectableListView?
    {
        guard abs(positions) == 1 else
        {
            log(error: "Moving list views by \(positions) positions is not supported.")
            return nil
        }
        
        let moveLeft = positions < 0
        
        let removalIndex = moveLeft ? 0 : listViews.count - 1
        listViews.remove(at: removalIndex).removeFromSuperview()
    
        return addListView(prepend: !moveLeft)
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
    
    // MARK: - Basics
    
    private var listViews = [SelectableListView]()
    
    private let browser = Browser()
}
