//
//  MainVC.swift
//  TodayList
//
//  Created by Sebastian on 12/06/17.
//  Copyright © 2017 Flowtoolz. All rights reserved.
//

import AppKit
import PureLayout

class MainVC: NSViewController
{
    override func loadView()
    {
        view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.gray.cgColor
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        layoutListViews()
    }
    
    override func viewDidAppear()
    {
        for listView in listViews
        {
            listView.jumpToTop()
        }
    }
    
    // MARK: - Task Lists
    
    func layoutListViews()
    {
        for i in 0 ..< listViews.count
        {
            let listView = listViews[i]
            
            if i == 0
            {
                listView.autoPinEdge(toSuperviewEdge: .left, withInset: 10)
            }
            else
            {
                listView.autoPinEdge(.left, to: .right, of: listViews[i - 1])
                listView.autoConstrainAttribute(.width, to: .width, of: listViews[i - 1])
            }
            
            if i == listViews.count - 1
            {
                listView.autoPinEdge(toSuperviewEdge: .right, withInset: 10)
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
