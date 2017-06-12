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
        
        layoutTaskList()
    }
    
    // MARK: - Tadsk List
    
    func layoutTaskList()
    {
        taskList.autoPinEdgesToSuperviewEdges()
    }
    
    lazy var taskList: TaskList =
    {
        let view = TaskList.newAutoLayout()
        self.view.addSubview(view)
        
        return view
    }()
}
