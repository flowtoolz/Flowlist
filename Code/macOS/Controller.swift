import AppKit
import PureLayout
import UIToolz
import SwiftObserver
import SwiftyToolz

class Controller: NSViewController, Observer
{
    // MARK: - Life Cycle
    
    deinit { stopAllObserving() }
    
    override func loadView()
    {
        view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(calibratedRed: 235.0 / 255.0,
                                              green: 235.0 / 255.0,
                                              blue: 235.0 / 255.0,
                                              alpha: 1.0).cgColor
    }
    
    // MARK: - View Delegate
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        createListViews()
        layoutListViews()
    }
    
    override func viewDidAppear()
    {
        for listView in listViews
        {
            listView.jumpToTop()
        }
        
        if listViews.count > 2
        {
            moveInputFocus(to: 2)
        }
    }

    // MARK: - Layout List Views
    
    func layoutListViews()
    {
        view.removeConstraints(listViewContraints)
        listViewContraints.removeAll()
        
        for i in 0 ..< listViews.count
        {
            let listView = listViews[i]
            
            if i == 0
            {
                listViewContraints.append(listView.autoPinEdge(.right,
                                                               to: .left,
                                                               of: view))
            }
            else
            {
                listViewContraints.append(listView.autoPinEdge(.left,
                                                               to: .right,
                                                               of: listViews[i - 1],
                                                               withOffset: 10))

                listViewContraints.append(listView.autoConstrainAttribute(.width,
                                                                          to: .width,
                                                                          of: listViews[i - 1]))
            }
            
            if i == listViews.count - 1
            {
                listViewContraints.append(listView.autoPinEdge(.left, to: .right, of: view))
            }
            
            listViewContraints.append(listView.autoPinEdge(toSuperviewEdge: .top))
            listViewContraints.append(listView.autoPinEdge(toSuperviewEdge: .bottom))
        }
    }
    
    private var listViewContraints = [NSLayoutConstraint]()
    
    // MARK: - List Views
    
    private func createListViews()
    {
        listViews.removeAll()
        
        for i in 0 ..< browser.numberOfLists
        {
            guard let list = browser.list(at: i) else
            {
                log(error: "Got nil list from browser at valid index \(i)")
                break
            }
            
            addListView(with: list)
        }
    }
    
    @discardableResult
    private func addListView(with list: SelectableList,
                             prepend: Bool = false) -> SelectableListView
    {
        let listView = SelectableListView(with: list)
        view.addSubview(listView)
        
        observe(listView: listView)
        
        if prepend
        {
            listViews.insert(listView, at: 0)
        }
        else
        {
            listViews.append(listView)
        }
        
        return listView
    }
    
    var listViews = [SelectableListView]()
    
    // MARK: - Observing Task List Views
    
    private func observe(listView: SelectableListView)
    {
        observe(listView)
        {
            [weak listView, weak self] request in
            
            guard let listView = listView else { return }
            
            self?.didReceive(request, from: listView)
        }
    }
    
    private func didReceive(_ request: SelectableListView.NavigationRequest,
                            from listView: SelectableListView)
    {
        switch request
        {
        case .wantsNothing: break
        case .wantsToPassFocusRight: passFocusRight(from: listView)
        case .wantsToPassFocusLeft: passFocusLeft(from: listView)
        case .wantsFocus: focus(listView)
        }
    }
    
    // MARK: - Navigation
    
    func passFocusRight(from listView: SelectableListView)
    {
        guard let index = listViews.index(where: { $0 === listView }),
            index >= 0, index < listViews.count - 1,
            (listView.list?.numberOfTasks ?? 0) > 0
        else
        {
            return
        }
        
        moveInputFocus(to: index + 1)
    }
    
    func passFocusLeft(from listView: SelectableListView)
    {
        guard let index = listViews.index(where: { $0 === listView }) else
        {
            return
        }
        
        moveInputFocus(to: index - 1)
    }
    
    @discardableResult
    private func moveInputFocus(to index: Int) -> Bool
    {
        guard listViews.isValid(index: index) else { return false }
        
        let listView = listViews[index]
        
        guard listView.list?.root != nil else { return false }
        
        if let firstTask = listView.list?.task(at: 0),
            listView.list?.selection.count == 0
        {
            listView.list?.selection.add(task: firstTask)
            listView.loadSelectionFromTaskList()
        }
        
        if !(NSApp.mainWindow?.makeFirstResponder(listView.tableView) ?? false)
        {
            log(warning: "Could not make table view first responder.")
            return false
        }
        
        tableViewGainedFocus(at: index)
        
        return true
    }
    
    func focus(_ listView: SelectableListView)
    {
        guard let index = listViews.index(where: { $0 === listView }) else
        {
            return
        }
        
        tableViewGainedFocus(at: index)
    }
    
    private func tableViewGainedFocus(at index: Int)
    {
        guard listViews.isValid(index: index),
            listViews[index].list?.root != nil
        else
        {
            return
        }
        
        // navigate right if necessary
        if index >= listViews.count - 2
        {
            navigateRight()
        }
            // navigate left if necessary
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
        let addedListView = addListView(with: rightList)
        addedListView.isHidden = true
        
        // animate the shit outa this
        NSAnimationContext.runAnimationGroup(
            {
                animationContext in
                
                animationContext.allowsImplicitAnimation = true
                animationContext.duration = 0.3
                
                // recreate layout contraints and re-layout all list views
                layoutListViews()
                
                view.layoutSubtreeIfNeeded()
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
        let addedListView = addListView(with: leftList, prepend: true)
        addedListView.isHidden = true

        // load and show selection of added list view
        addedListView.loadSelectionFromTaskList()
        
        // animate the shit outa this
        NSAnimationContext.runAnimationGroup(
            {
                animationContext in
                
                animationContext.allowsImplicitAnimation = true
                animationContext.duration = 0.3
                
                // recreate layout contraints and re-layout all list views
                layoutListViews()
                
                view.layoutSubtreeIfNeeded()
            },
            completionHandler:
            {
                addedListView.isHidden = false
            }
        )
    }
    
    private let browser = Browser()
}
