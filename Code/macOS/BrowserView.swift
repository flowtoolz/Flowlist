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
        
        backgroundColor = Color.background
        
        createListViews()
        layoutListViews()
    }
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
    deinit { stopAllObserving() }
    
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
        observe(listView)
        {
            [weak listView, weak self] request in
            
            guard let listView = listView else { return }
            
            self?.didReceive(request, from: listView)
        }
    }
    
    private func didReceive(_ request: ScrollTable.NavigationRequest,
                            from listView: SelectableListView)
    {
        switch request
        {
        case .wantsNothing: break
        case .wantsToPassFocusRight: passFocusRight(from: listView)
        case .wantsToPassFocusLeft: passFocusLeft(from: listView)
        case .wantsToBeRevealed: navigateTo(listView)
        }
    }
    
    // MARK: - Navigation
    
    private func passFocusRight(from listView: SelectableListView)
    {
        guard let index = listViews.index(where: { $0 === listView }),
            index >= 0, index < listViews.count - 1,
            (listView.list?.numberOfTasks ?? 0) > 0 else { return }
        
        focusList(at: index + 1)
    }
    
    private func passFocusLeft(from listView: SelectableListView)
    {
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
            listView.scrollTable.tableView.loadSelectionFromList()
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
        guard listViews.isValid(index: index),
            listViews[index].list?.root != nil else { return }
        
        if index >= listViews.count - 2
        {
            navigateRight()
        }
        else if index <= 1
        {
            navigateLeft()
        }
    }
    
    private func navigateRight()
    {
        // remove list view from front
        let removedListView = listViews.remove(at: 0)
        removedListView.removeFromSuperview()
        
        // let coordinator go right
        let rightList = browser.moveRight()
        
        // append new list view to end
        let addedListView = addListView()
        addedListView.configure(with: rightList)
        addedListView.isHidden = true
        
        // animate the shit outa this
        NSAnimationContext.runAnimationGroup(
            {
                animationContext in
                
                animationContext.allowsImplicitAnimation = true
                animationContext.duration = 0.3
                
                // recreate layout contraints and re-layout all list views
                layoutListViews()
                
                layoutSubtreeIfNeeded()
            },
            completionHandler:
            {
                addedListView.isHidden = false
            }
        )
    }
    
    private func navigateLeft()
    {
        // remove list view from end
        guard let removedListView = listViews.popLast() else { return }
        removedListView.removeFromSuperview()
        
        // let coordinator go left
        let leftList = browser.moveLeft()
        
        // add new list view to front
        let addedListView = addListView(prepend: true)
        addedListView.configure(with: leftList)
        addedListView.isHidden = true
        
        // load and show selection of added list view
        addedListView.scrollTable.tableView.loadSelectionFromList()
        
        // animate the shit outa this
        NSAnimationContext.runAnimationGroup(
            {
                animationContext in
                
                animationContext.allowsImplicitAnimation = true
                animationContext.duration = 0.3
                
                // recreate layout contraints and re-layout all list views
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
