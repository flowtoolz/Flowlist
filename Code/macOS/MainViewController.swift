import AppKit
import PureLayout
import UIToolz
import SwiftObserver
import SwiftyToolz

class MainViewController: NSViewController, Observer
{
    // MARK: - Life Cycle
    
    deinit
    {
        stopAllObserving()
    }
    
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
            _ = moveInputFocus(to: 2)
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
        
        for list in viewModel.lists
        {
            addListView(with: list)
        }
    }
    
    @discardableResult
    private func addListView(with list: TaskListViewModel,
                             prepend: Bool = false) -> TaskListView
    {
        let listView = TaskListView(with: list)
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
    
    var listViews = [TaskListView]()
    
    // MARK: - Observing Task List Views
    
    private func observe(listView: TaskListView)
    {
        observe(listView)
        {
            [weak listView, weak self] event in
            
            guard let listView = listView else { return }
            
            self?.didReceive(event, from: listView)
        }
    }
    
    private func didReceive(_ event: TaskListView.Event,
                            from listView: TaskListView)
    {
        switch(event)
        {
        case .none: break
        case .wantToGiveUpFocusToTheRight:
            listViewWantsToGiveFocusToTheRight(listView)
        case .wantToGiveUpFocusToTheLeft:
            listViewWantsToGiveFocusToTheLeft(listView)
        case .tableViewWasClicked:
            tableViewWasClickedInTaskListView(listView)
        }
    }
    
    // MARK: - Navigation
    
    func listViewWantsToGiveFocusToTheRight(_ listView: TaskListView)
    {
        guard let index = listViews.index(where: { $0 === listView }),
            index >= 0, index < listViews.count - 1,
            (listView.taskList?.numberOfTasks ?? 0) > 0
        else
        {
            return
        }
        
        _ = moveInputFocus(to: index + 1)
    }
    
    func listViewWantsToGiveFocusToTheLeft(_ listView: TaskListView)
    {
        guard let index = listViews.index(where: { $0 === listView }) else
        {
            return
        }
        
        _ = moveInputFocus(to: index - 1)
    }
    
    private func moveInputFocus(to index: Int) -> Bool
    {
        guard listViews.isValid(index: index) else { return false }
        
        let listView = listViews[index]
        
        guard listView.taskList?.supertask != nil else { return false }
        
        if listView.taskList?.numberOfTasks ?? 0 > 0
        {
            let selectionIndex = listView.taskList?.selection.indexes.first ?? 0
            
            // TODO: do we need this? why reset selection to first selection when setting input focus???
            if let selectedTask = listView.taskList?.task(at: selectionIndex)
            {
                listView.taskList?.selection.removeAll()
                listView.taskList?.selection.add(selectedTask)
                listView.updateTableSelection()
            }
        }
        else
        {
            listView.taskList?.selection.removeAll()
        }
        
        if !(NSApp.mainWindow?.makeFirstResponder(listView.tableView) ?? false)
        {
            log(warning: "Could not make table view first responder.")
            return false
        }
        
        tableViewGainedFocus(at: index)
        
        return true
    }
    
    func tableViewWasClickedInTaskListView(_ listView: TaskListView)
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
            listViews[index].taskList?.supertask != nil
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
        let rightList = viewModel.moveRight()
        
        // append new list view to end
        let addedListView = addListView(with: rightList)
        addedListView.isHidden = true
        
        // let coordinator update new list
        viewModel.setContainerOfLastList()
        
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
        let leftList = viewModel.moveLeft()
        
        // add new list view to front
        let addedListView = addListView(with: leftList, prepend: true)
        addedListView.isHidden = true
        
        // let coordinator update new list
        viewModel.setContainerOfMaster(at: 0)
        
        // load and show selection of added list view
        viewModel.selectSlaveInMaster(at: 0)
        addedListView.updateTableSelection()
        
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
    
    private let viewModel = MainViewModel()
}
