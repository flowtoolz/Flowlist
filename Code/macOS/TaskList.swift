//
//  TaskList.swift
//  TodayList
//
//  Created by Sebastian on 12/06/17.
//  Copyright © 2017 Flowtoolz. All rights reserved.
//

import AppKit
import PureLayout

class TaskList: NSScrollView, NSTableViewDelegate, NSTableViewDataSource
{
    // MARK: - Table View
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        initialize()
    }
    
    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        
        initialize()
    }
    
    private func initialize()
    {
        hasVerticalScroller = true
        
        documentView = tableView
    }
    
    private lazy var tableView: NSTableView =
    {
        let view = NSTableView()
        
        let column = NSTableColumn(identifier: TaskListCell.reuseIdentifier)
        column.title = "Task List Title"
        view.addTableColumn(column)
        
        view.allowsMultipleSelection = true
  
        view.dataSource = self
        view.delegate = self
        
        return view
    }()
    
    // MARK: - Table View Data Source
    
    func numberOfRows(in tableView: NSTableView) -> Int
    {
        return taskStore.tasks.count
    }
    
    func tableView(_ tableView: NSTableView,
                   viewFor tableColumn: NSTableColumn?,
                   row: Int) -> NSView?
    {
        guard tableColumn?.identifier == TaskListCell.reuseIdentifier else
        {
            Swift.print("warning: tableColumn has weird or nil identifier: \(tableColumn?.identifier ?? "nil")")
            return nil
        }

        let cell = tableView.make(withIdentifier: TaskListCell.reuseIdentifier,
                                  owner: self) as? TaskListCell ?? TaskListCell()
        
        cell.configure(with: taskStore.tasks[row])
        
        return cell
    }
}
