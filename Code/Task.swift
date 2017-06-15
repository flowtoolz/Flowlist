//
//  Task.swift
//  TodayList
//
//  Created by Sebastian on 12/06/17.
//  Copyright © 2017 Flowtoolz. All rights reserved.
//

class Task
{
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
    
    var title: String?
    
    var state: State?
    
    enum State: Int
    {
        // state == nil is default and kind of a backlog or "no specific state" 
        case inProgress, onHold, done, archived
    }
    
    func insert(_ task: Task, at index: Int)
    {
        guard index >= 0, index <= numberOfElements else
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
    
    func task(at index: Int) -> Task?
    {
        guard index >= 0, index < numberOfElements else
        {
            print("Warning: tried to access Task at an out of bound index")
            return nil
        }
        
        return elements?[index]
    }
    
    var isContainer: Bool
    {
        return numberOfElements > 0
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
    
    var numberOfElements: Int
    {
        return elements?.count ?? 0
    }
    
    weak var container: Task?
    var elements: [Task]?
    
    let uuid: String
    
    var description: String
    {
        return "\(uuid) \(title ?? "Untitled")"
    }
}

