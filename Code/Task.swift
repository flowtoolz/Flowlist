//
//  Task.swift
//  TodayList
//
//  Created by Sebastian on 12/06/17.
//  Copyright © 2017 Flowtoolz. All rights reserved.
//

import Flowtoolz

class Task: Sender
{
    // MARK: - Initialization
    
    convenience init(with uuid: String, title: String?, state: State?)
    {
        self.init(with: uuid)
        
        self.title = title
        
        self.state = state
    }
    
    init(with uuid: String)
    {
        self.uuid = uuid
    }
    
    // MARK: - Edit Hierarchy
    
    func insert(_ task: Task, at index: Int) -> Bool
    {
        guard index >= 0, index <= subtasks.count else
        {
            print("Warning: tried to insert Task at an out of bound index into another task")
            return false
        }
        
        if elements == nil
        {
            elements = [Task]()
        }
        
        elements?.insert(task, at: index)
        
        task.container = self
        
        send(Task.didChangeSubtasks, parameters: ["method": "insert",
                                                 "index": index])
        
        return true
    }
    
    func deleteSubtasks(at indexes: [Int]) -> Bool
    {
        var sorted = indexes.sorted()
        
        guard let maxIndex = sorted.last,
            let minIndex = sorted.first,
            minIndex >= 0, maxIndex < subtasks.count
        else
        {
            print("Warning: tried to delete tasks with at least one out of bound index")
            return false
        }
    
        while let indexToRemove = sorted.popLast()
        {
            if let removedSubtask = elements?.remove(at: indexToRemove)
            {
                removedSubtask.container = nil
            }
        }
        
        send(Task.didChangeSubtasks, parameters: ["method": "delete",
                                                  "indexes": indexes])
        
        return true
    }
    
    static let didChangeSubtasks = "TaskDidChangeSubtasks"
    
    // MARK: - Read Hierarchy
    
    var isContainer: Bool
    {
        return subtasks.count > 0
    }
    
    func subtask(at index: Int) -> Task?
    {
        guard index >= 0, index < subtasks.count else
        {
            print("Warning: tried to access Task at an out of bound index")
            return nil
        }
        
        return subtasks[index]
    }
    
    var subtasks: [Task]
    {
        return elements ?? []
    }
    
    func allSubtasksRecursively() -> [Task]
    {
        var tasks = [self]
        
        if let elements = elements
        {
            for task in elements
            {
                tasks.append(contentsOf: task.allSubtasksRecursively())
            }
        }
        
        return tasks
    }

    var indexInContainer: Int?
    {
        guard let container = container else
        {
            return nil
        }
        
        return container.elements?.index
        {
            element in
            
            return element.uuid == self.uuid
        }
    }
    
    private(set) weak var container: Task?
    
    private var elements: [Task]?
    
    // MARK: - Data
    
    var title: String?
    {
        didSet
        {
            if title != oldValue
            {
                send(Task.didChangeTitle)
            }
        }
    }
    
    static let didChangeTitle = "TaskDidChangeTitle"
    
    var state: State?
    {
        didSet
        {
            if state != oldValue
            {
                send(Task.didChangeState)
            }
        }
    }
    
    static let didChangeState = "TaskDidChangeState"
    
    enum State: Int
    {
        // state == nil is default and kind of a backlog or "no specific state"
        case inProgress, onHold, done, archived
    }
    
    var description: String
    {
        return "\(uuid) \(title ?? "Untitled")"
    }
    
    let uuid: String
}

