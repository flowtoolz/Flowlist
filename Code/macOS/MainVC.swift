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
        let imageName = Int(arc4random_uniform(2)) == 0 ? "flower" : "zen"
        let image = NSImage(named: imageName) ?? NSImage()
        
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
        
        _ = moveFocus(to: index + 1, resetSelection: true)
    }
    
    func listViewWantsToGiveFocusToTheLeft(sender: Any)
    {
        guard let index = listViews.index(where: { $0 === sender as AnyObject }) else
        {
            return
        }
        
        _ = moveFocus(to: index - 1)
    }
    
    private func moveFocus(to index: Int, resetSelection: Bool = false) -> Bool
    {
        guard index >= 0, index < listViews.count else { return false }
        
        let listView = listViews[index]
        
        guard listView.taskList?.numberOfTasks ?? 0 > 0 else { return false }
        
        if resetSelection
        {
            let selectionIndex = listView.taskList?.selectedIndexes.min() ?? 0
            listView.taskList?.selectedIndexes = [selectionIndex]
            listView.updateTableSelection()
        }
        
        listView.scrollView.becomeFirstResponder()
        
        return false
    }
    
    // MARK: - Task Lists
    
    func layoutListViews()
    {
        for i in 0 ..< listViews.count
        {
            let listView = listViews[i]
            
            if i == 0
            {
                listView.autoPinEdge(toSuperviewEdge: .left, withInset: 150)
            }
            else
            {
                listView.autoPinEdge(.left, to: .right, of: listViews[i - 1])
                listView.autoConstrainAttribute(.width, to: .width, of: listViews[i - 1])
            }
            
            if i == listViews.count - 1
            {
                listView.autoPinEdge(toSuperviewEdge: .right, withInset: 150)
            }
            
            listView.autoPinEdge(toSuperviewEdge: .top)
            listView.autoPinEdge(toSuperviewEdge: .bottom)
        }
    }
    
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
