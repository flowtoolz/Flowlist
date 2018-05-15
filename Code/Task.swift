import SwiftObserver
import SwiftyToolz

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
    
    func log()
    {
        print(description)
    }
    
    var description: String
    {
        return encode()?.utf8String ?? typeName(of: self)
    }
    
    // MARK: - Edit Hierarchy
    
    func setContainers()
    {
        for subtask in subtasks
        {
            subtask.supertask = self
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
        
        subtasks.insert(task, at: index)
        
        task.supertask = self
        
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
            let removedSubtask = subtasks.remove(at: indexToRemove)
            
            removedSubtasks.append(removedSubtask)
            
            if removedSubtask.supertask === self
            {
                removedSubtask.supertask = nil
            }
        }
        
        send(.didChangeSubtasks(method: .delete, indexes: indexes))
        
        return removedSubtasks
    }
    
    func moveSubtask(from: Int, to: Int) -> Bool
    {
        let didMove = subtasks.moveElement(from: from, to: to)
        
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
    
    func allSubtasksRecursively() -> [Task]
    {
        var tasks = [self]

        for task in subtasks
        {
            tasks.append(contentsOf: task.allSubtasksRecursively())
        }
        
        return tasks
    }

    var indexInContainer: Int?
    {
        return supertask?.index(of: self)
    }
    
    func index(of subtask: Task) -> Int?
    {
        return subtasks.index(where: { $0 === subtask })
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
    
    // MARK: - Supertask
    
    private(set) weak var supertask: Task? = nil
    
    // MARK: - Subtasks
    
    private(set) var subtasks = [Task]()
    
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
