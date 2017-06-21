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
                if removedSubtask.container === self
                {
                    removedSubtask.container = nil
                }
            }
        }
        
        send(Task.didChangeSubtasks, parameters: ["method": "delete",
                                                  "indexes": indexes])
        
        return true
    }
    
    static let didChangeSubtasks = "TaskDidChangeSubtasks"
    
    func moveSubtask(from: Int, to: Int) -> Bool
    {
        let didMove = elements?.moveElement(from: from, to: to) ?? false
        
        if didMove
        {
            send(Task.didMoveSubtask, parameters: ["from": from, "to": to])
        }
        
        return didMove
    }
    
    static let didMoveSubtask = "TaskDidMoveSubtask"
    
//    func moveTasks(at indexes: [Int], to index: Int) -> Bool
//    {
//        print("about to move tasks at \(indexes.description) to index \(index)")
//        
//        guard index >= 0, index < subtasks.count,
//            let elements = elements,
//            let minIndex = indexes.min(), minIndex >= 0,
//            let maxIndex = indexes.max(), maxIndex < subtasks.count
//        else
//        {
//            return false
//        }
//        
//        var resultingArray = [Task]()
//        
//        // copy old tasks that are above target index
//        for i in 0 ..< index
//        {
//            if !indexes.contains(i)
//            {
//                resultingArray.append(elements[i])
//            }
//        }
//        
//        let startIndexAfterMove = resultingArray.count
//        
//        // copy tasks to move
//        for indexToMove in indexes.sorted()
//        {
//            resultingArray.append(elements[indexToMove])
//        }
//        
//        // copy old tasks that are at or below target index
//        for i in index ..< subtasks.count
//        {
//            if !indexes.contains(i)
//            {
//                resultingArray.append(elements[i])
//            }
//        }
//        
//        // replace task array with result
//        self.elements = resultingArray
//        
//        // calculate new indexes
//        var resultingIndexes = [Int]()
//        
//        for i in startIndexAfterMove ..< startIndexAfterMove + indexes.count
//        {
//            resultingIndexes.append(i)
//        }
//        
//        // notify others of the move
//        send(Task.didMoveSubtasks, parameters: ["fromIndexes": indexes,
//                                                "toIndexes": resultingIndexes])
//        
//        return true
//    }
    
    static let didMoveSubtasks = "TaskDidMoveSubtasks"
    
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
        return container?.index(of: self)
    }
    
    func index(of subtask: Task) -> Int?
    {
        return elements?.index(where: { $0 === subtask })
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
    
    func logRecursively(_ numberIndents: Int = 0)
    {
        for _ in 0 ..< numberIndents
        {
            print("\t", separator: "", terminator: "")
        }
        
        print(description)
        
        if (elements ?? []).count > 0
        {
            for _ in 0 ..< numberIndents
            {
                print("\t", separator: "", terminator: "")
            }
            
            print("{")
            
            for element in elements ?? []
            {
                element.logRecursively(numberIndents + 1)
            }
            
            for _ in 0 ..< numberIndents
            {
                print("\t", separator: "", terminator: "")
            }
            
            print("}")
        }
    }
    
    var description: String
    {
        let containerTitle = container == nil ? "none" : (container?.title ?? "untitled")
        let stateString = state == .done ? "done" : "backlog"
        return "\(title ?? "untitled") (container: \(containerTitle), state: \(stateString))"
    }
    
    let uuid: String
}

