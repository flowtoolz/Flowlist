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
        
        layoutMainList()
        layoutDetailList()
    }
    
    // MARK: - Task Lists
    
    func layoutMainList()
    {
        mainList.autoPinEdge(toSuperviewEdge: .top)
        mainList.autoPinEdge(toSuperviewEdge: .bottom)
        mainList.autoPinEdge(toSuperviewEdge: .left)
        mainList.autoConstrainAttribute(.right,
                                        to: .right,
                                        of: view,
                                        withMultiplier: 0.66)
    }
    
    lazy var mainList: TaskList =
    {
        let view = TaskList.newAutoLayout()
        self.view.addSubview(view)
        
        return view
    }()
    
    func layoutDetailList()
    {
        detailList.autoPinEdge(toSuperviewEdge: .top)
        detailList.autoPinEdge(toSuperviewEdge: .bottom)
        detailList.autoPinEdge(toSuperviewEdge: .right)
        detailList.autoPinEdge(.left, to: .right, of: mainList)
    }
    
    lazy var detailList: TaskList =
    {
        let view = TaskList.newAutoLayout()
        self.view.addSubview(view)
        
        view.tableView.isEnabled = false
        view.hasVerticalScroller = false
        
        return view
    }()
}
