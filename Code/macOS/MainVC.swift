//
//  MainVC.swift
//  TodayList
//
//  Created by Sebastian on 12/06/17.
//  Copyright © 2017 Flowtoolz. All rights reserved.
//

import AppKit
import PureLayout
import Flowtoolz

class MainVC: NSViewController, Subscriber
{
    override func loadView()
    {
        view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.gray.cgColor
        
        subscribe(to: TaskListView.wantsToGiveUpFocusToTheRight,
                  action: listViewWantsToGiveFocusToTheRight)
        
        subscribe(to: TaskListView.wantsToGiveUpFocusToTheLeft,
                  action: listViewWantsToGiveFocusToTheLeft)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        layoutBackroundImage()
        layoutListViews()
    }
    
    override func viewDidAppear()
    {
        for listView in listViews
        {
            listView.jumpToTop()
        }
    }
    
    // MARK: - Background Image
    
    private func layoutBackroundImage()
    {
        backgroundImage.autoPinEdgesToSuperviewEdges()
    }
    
    private lazy var backgroundImage: NSImageView =
    {
        let image = NSImage(named: "zen") ?? NSImage()
        
        let view = NSImageView(withAspectFillImage: image)
        self.view.addSubview(view)
        
        return view
    }()
    
    // MARK: - Navigation
    
    func listViewWantsToGiveFocusToTheRight(sender: Any)
    {
        guard let index = listViews.index(where: { $0 === sender as AnyObject }) else
        {
            return
        }
        
        _ = moveInputFocus(to: index + 1)
    }
    
    func listViewWantsToGiveFocusToTheLeft(sender: Any)
    {
        guard let index = listViews.index(where: { $0 === sender as AnyObject }) else
        {
            return
        }
        
        _ = moveInputFocus(to: index - 1)
    }
    
    private func moveInputFocus(to index: Int) -> Bool
    {
        guard index >= 0, index < listViews.count else { return false }
        
        // set focus
        let listView = listViews[index]
        
        guard listView.taskList?.numberOfTasks ?? 0 > 0 else { return false }
        
        let selectionIndex = listView.taskList?.selectedIndexes.min() ?? 0
        listView.taskList?.selectedIndexes = [selectionIndex]
        listView.updateTableSelection()
        
        listView.scrollView.becomeFirstResponder()
        
        // navigate right if becessary
        if index >= listViews.count - 2
        {
            navigateRight()
        }
        
        // navigate left if becessary
        else if index <= 1
        {
            navigateLeft()
        }
        
        return true
    }
    
    private func navigateRight()
    {
        // remove list view from front
        let removedListView = listViews.remove(at: 0)
        removedListView.removeFromSuperview()
        
        // let coordinator go right
        let rightList = listCoordinator.moveRight()
        
        // append new list view to end
        let addedListView = TaskListView(with: rightList)
        addedListView.isHidden = true
        self.view.addSubview(addedListView)
        listViews.append(addedListView)
        
        // let coordinator update new list
        listCoordinator.setContainerOfLastList()

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
        })
    }

    private func navigateLeft()
    {
        // remove list view from end
        guard let removedListView = listViews.popLast() else { return }
        removedListView.removeFromSuperview()
        
        // let coordinator go left
        let leftList = listCoordinator.moveLeft()
        
        // add new list view to front
        let addedListView = TaskListView(with: leftList)
        addedListView.isHidden = true
        view.addSubview(addedListView)
        listViews.insert(addedListView, at: 0)
        
        // let coordinator update new list
        listCoordinator.setContainerOfMaster(at: 0)
        
        // load and show selection of added list view
        listCoordinator.selectSlaveInMaster(at: 0)
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
        })
    }

    // MARK: - Task Lists
    
    func layoutListViews()
    {
        view.removeConstraints(listViewContraints)
        listViewContraints.removeAll()
        
        for i in 0 ..< listViews.count
        {
            let listView = listViews[i]
            
            if i == 0
            {
                listViewContraints.append(listView.autoPinEdge(.right, to: .left, of: view))
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
    
    lazy var listViews: [TaskListView] =
    {
        var listViews = [TaskListView]()
        
        for list in listCoordinator.lists
        {
            let listView = TaskListView(with: list)
            self.view.addSubview(listView)
            
            listViews.append(listView)
        }
        
        return listViews
    }()
}
