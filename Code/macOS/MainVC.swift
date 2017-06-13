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
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.gray.cgColor
        
        layoutTaskList()
    }
    
    // MARK: - Tadsk List
    
    func layoutTaskList()
    {
        taskList.autoPinEdge(toSuperviewEdge: .top)
        taskList.autoPinEdge(toSuperviewEdge: .bottom)
        taskList.autoConstrainAttribute(.left, to: .right, of: view, withMultiplier: 0.33)
        taskList.autoConstrainAttribute(.right, to: .right, of: view, withMultiplier: 0.66)
    }
    
    lazy var taskList: TaskList =
    {
        let view = TaskList.newAutoLayout()
        self.view.addSubview(view)
        
        return view
    }()
}
