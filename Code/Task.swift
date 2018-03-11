import Flowtoolz

class Task: Sender, Codable
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
    
    // MARK: - Logging
    
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
        
//        if elements == nil
//        {
//            elements = [Task]()
//        }
        
        elements.insert(task, at: index)
        
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
            let removedSubtask = elements.remove(at: indexToRemove)
            
            if removedSubtask.container === self
            {
                removedSubtask.container = nil
            }
        }
        
        send(Task.didChangeSubtasks, parameters: ["method": "delete",
                                                  "indexes": indexes])
        
        return true
    }
    
    static let didChangeSubtasks = "TaskDidChangeSubtasks"
    
    func moveSubtask(from: Int, to: Int) -> Bool
    {
        let didMove = elements.moveElement(from: from, to: to) ?? false
        
        if didMove
        {
            send(Task.didMoveSubtask, parameters: ["from": from, "to": to])
        }
        
        return didMove
    }
    
    static let didMoveSubtask = "TaskDidMoveSubtask"
    
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
    
    enum State: Int, Codable
    {
        // state == nil is default and kind of a backlog or "no specific state"
        case inProgress, onHold, done, archived
    }
    
    private(set) weak var container: Task? = nil
    
    private var elements = [Task]()
}
