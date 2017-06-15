//
//  Task.swift
//  TodayList
//
//  Created by Sebastian on 12/06/17.
//  Copyright © 2017 Flowtoolz. All rights reserved.
//

class Task
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
    
    func insert(_ task: Task, at index: Int)
    {
        guard index >= 0, index <= subTasks.count else
        {
            print("Warning: tried to insert Task at an out of bound index into another task")
            return
        }
        
        if elements == nil
        {
            elements = [Task]()
        }
        
        elements?.insert(task, at: index)
        
        task.container = self
    }
    
    func deleteTask(at index: Int) -> Bool
    {
        guard index >= 0, index < subTasks.count else
        {
            print("Warning: tried to delete task at an out of bound index")
            return false
        }
        
        elements?.remove(at: index)
        
        return true
    }
    
    // MARK: - Read Hierarchy
    
    var isContainer: Bool
    {
        return subTasks.count > 0
    }
    
    func task(at index: Int) -> Task?
    {
        guard index >= 0, index < subTasks.count else
        {
            print("Warning: tried to access Task at an out of bound index")
            return nil
        }
        
        return elements?[index]
    }
    
    var subTasks: [Task]
    {
        return elements ?? []
    }
    
    func allTasksRecursively() -> [Task]
    {
        var tasks = [self]
        
        if let elements = elements
        {
            for task in elements
            {
                tasks.append(contentsOf: task.allTasksRecursively())
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
    
    weak var container: Task?
    
    private var elements: [Task]?
    
    // MARK: - Data
    
    let uuid: String
    
    var description: String
    {
        return "\(uuid) \(title ?? "Untitled")"
    }
    
    var title: String?
    
    var state: State?
    
    enum State: Int
    {
        // state == nil is default and kind of a backlog or "no specific state"
        case inProgress, onHold, done, archived
    }
}

