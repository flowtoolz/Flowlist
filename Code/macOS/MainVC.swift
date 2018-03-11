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
    // MARK: - View Life Cycle
    
    override func loadView()
    {
        view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(calibratedRed: 235.0 / 255.0,
                                              green: 235.0 / 255.0,
                                              blue: 235.0 / 255.0,
                                              alpha: 1.0).cgColor
        
        subscribe(to: TaskListView.wantsToGiveUpFocusToTheRight,
                  action: listViewWantsToGiveFocusToTheRight)
        
        subscribe(to: TaskListView.wantsToGiveUpFocusToTheLeft,
                  action: listViewWantsToGiveFocusToTheLeft)
        
        subscribe(to: TaskListView.tableViewWasClicked,
                  action: tableViewWasClickedInTaskListView)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // layoutBackroundImage()
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
    
    // MARK: - Background Image
    
    private func layoutBackroundImage()
    {
        backgroundImage.autoPinEdgesToSuperviewEdges()
        backgroundOverlay.autoPinEdgesToSuperviewEdges()
    }
    
    private lazy var backgroundOverlay: NSView =
    {
        let view = NSView.newAutoLayout()
        self.view.addSubview(view)
        
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.4).cgColor
        
        return view
    }()
    
    private lazy var backgroundImage: NSImageView =
    {
        let image = NSImage(named: NSImage.Name(rawValue: "grass")) ?? NSImage()
        
        let view = NSImageView(withAspectFillImage: image)
        self.view.addSubview(view)
        
        return view
    }()
    
    // MARK: - Navigation
    
    func listViewWantsToGiveFocusToTheRight(sender: Any)
    {
        guard let index = listViews.index(where: { $0 === sender as AnyObject }),
            index >= 0, index < listViews.count - 1,
            (listViews[index].taskList?.tasks.count ?? 0) > 0
        else
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
        
        let listView = listViews[index]
        
        guard listView.taskList?.container != nil else { return false }
        
        if listView.taskList?.tasks.count ?? 0 > 0
        {
            let selectionIndex = listView.taskList?.selectedIndexesSorted.first ?? 0
            
            // TODO: do we need this? why reset selection to first selection when setting input focus???
            if let selectedTask = listView.taskList?.task(at: selectionIndex)
            {
                listView.taskList?.selectedTasksByUuid = [selectedTask.uuid : selectedTask]
                listView.updateTableSelection()
            }
        }
        else
        {
            listView.taskList?.selectedTasksByUuid = [:]
        }
        
        if !(NSApp.mainWindow?.makeFirstResponder(listView.tableView) ?? false)
        {
            print("Warning: could not make table view first responder")
            return false
        }
        
        tableViewGainedFocus(at: index)

        return true
    }
    
    func tableViewWasClickedInTaskListView(sender: Any)
    {
        guard let index = listViews.index(where: { $0 === sender as AnyObject }) else
        {
            return
        }
        
        tableViewGainedFocus(at: index)
    }
    
    private func tableViewGainedFocus(at index: Int)
    {
        guard index >= 0, index < listViews.count,
            listViews[index].taskList?.container != nil
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

    // MARK: - Task List Views
    
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
//                if i == 2
//                {
//                    listViewContraints.append(listView.autoConstrainAttribute(.width,
//                                                                              to: .width,
//                                                                              of: view,
//                                                                              withMultiplier: 0.33))
//                }
//                else
//                {
//                    listViewContraints.append(listView.autoConstrainAttribute(.width,
//                                                                              to: .width,
//                                                                              of: listViews[1]))
//                }
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
