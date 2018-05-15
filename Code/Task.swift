import SwiftObserver

class Task: Codable, Observable, Observer
{
    // MARK: - Initialization
    
    convenience init(with uuid: String,
                     title: String? = nil,
                     state: State? = nil)
    {
        self.init(with: uuid)
        
        self.title = title
        
        self.state = state
    }
    
    init(with uuid: String)
    {
        self.uuid = uuid
    }
    
    // MARK: - Logging
    
    func logRecursively(_ numberIndents: Int = 0)
    {
        for _ in 0 ..< numberIndents
        {
            print("\t", separator: "", terminator: "")
        }
        
        print(description)
        
        if elements.count > 0
        {
            for _ in 0 ..< numberIndents
            {
                print("\t", separator: "", terminator: "")
            }
            
            print("{")
            
            for element in elements
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
    
    // MARK: - Edit Hierarchy
    
    func setContainers()
    {
        for subtask in subtasks
        {
            subtask.container = self
            subtask.setContainers()
        }
    }
    
    func groupTasks(at indexes: [Int], as group: Task) -> Int?
    {
        guard let groupIndex = indexes.min() else
        {
            return nil
        }

        for index in indexes
        {
            if let subtask = subtask(at: index)
            {
                _ = group.insert(subtask, at: group.subtasks.count)
            }
        }
        
        _ = deleteSubtasks(at: indexes)
        
        _ = insert(group, at: groupIndex)
        
        return groupIndex
    }
    
    @discardableResult
    func insert(_ task: Task, at index: Int) -> Bool
    {
        guard index >= 0, index <= subtasks.count else
        {
            print("Warning: tried to insert Task at an out of bound index into another task")
            return false
        }
        
        elements.insert(task, at: index)
        
        task.container = self
        
        send(.didChangeSubtasks(method: .insert, indexes: [index]))
        
        return true
    }
    
    func deleteSubtasks(at indexes: [Int]) -> [Task]
    {
        var sorted = indexes.sorted()
        
        guard let maxIndex = sorted.last,
            let minIndex = sorted.first,
            minIndex >= 0, maxIndex < subtasks.count
        else
        {
            print("Warning: tried to delete tasks with at least one out of bound index")
            return []
        }
    
        var removedSubtasks = [Task]()
        
        while let indexToRemove = sorted.popLast()
        {
            let removedSubtask = elements.remove(at: indexToRemove)
            
            removedSubtasks.append(removedSubtask)
            
            if removedSubtask.container === self
            {
                removedSubtask.container = nil
            }
        }
        
        send(.didChangeSubtasks(method: .delete, indexes: indexes))
        
        return removedSubtasks
    }
    
    func moveSubtask(from: Int, to: Int) -> Bool
    {
        let didMove = elements.moveElement(from: from, to: to)
        
        if didMove
        {
            send(.didMoveSubtask(from: from, to: to))
        }
        
        return didMove
    }
    
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
        return elements
    }
    
    func allSubtasksRecursively() -> [Task]
    {
        var tasks = [self]

        for task in elements
        {
            tasks.append(contentsOf: task.allSubtasksRecursively())
        }
        
        return tasks
    }

    var indexInContainer: Int?
    {
        return container?.index(of: self)
    }
    
    func index(of subtask: Task) -> Int?
    {
        return elements.index(where: { $0 === subtask })
    }
    
    // MARK: - Data
    
    let uuid: String
    
    var title: String?
    {
        didSet
        {
            if title != oldValue
            {
                send(.didChangeTitle)
            }
        }
    }
    
    var state: State?
    {
        didSet
        {
            if state != oldValue
            {
                send(.didChangeState)
            }
        }
    }
    
    enum State: Int, Codable
    {
        // state == nil is default and kind of a backlog or "no specific state"
        case inProgress, onHold, done, archived
    }
    
    private(set) weak var container: Task? = nil
    
    private var elements = [Task]()
    
    // MARK: - Event
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event
    {
        case didNothing
        case didChangeState
        case didChangeTitle
        case didMoveSubtask(from: Int, to: Int)
        case didChangeSubtasks(method: Method, indexes: [Int])
        
        enum Method
        {
            case delete, insert
        }
    }
}
