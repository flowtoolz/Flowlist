import SwiftObserver
import SwiftyToolz

class Task: Codable, Observable
{
    // MARK: - Initialization
    
    convenience init(with uuid: String,
                     title: String? = nil,
                     state: State? = nil)
    {
        self.init()
        
        self.title = title
        self.state = state
    }
    
    // MARK: - Edit Subtasks
    
    @discardableResult
    func groupTasks(at indexes: [Int], as group: Task) -> Int?
    {
        let sortedIndexes = indexes.sorted()
        
        guard
            let groupIndex = sortedIndexes.first,
            subtasks.isValid(index: groupIndex),
            subtasks.isValid(index: sortedIndexes.last)
        else
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
        
        _ = removeSubtasks(at: indexes)
        
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
        
        send(.didInsertSubtask(index: index))
        
        return true
    }
    
    @discardableResult
    func removeSubtasks(at indexes: [Int]) -> [Task]
    {
        var sortedIndexes = indexes.sorted()
        
        guard
            subtasks.isValid(index: sortedIndexes.first),
            subtasks.isValid(index: sortedIndexes.last)
        else
        {
            print("Warning: tried to remove tasks with at least one out of bound index")
            return []
        }
    
        var removedSubtasks = [Task]()
        
        while let indexToRemove = sortedIndexes.popLast()
        {
            let removedSubtask = subtasks.remove(at: indexToRemove)
            
            // FIXME: was this condition necessary for some side effect? avoid it!
            if removedSubtask.supertask === self
            {
                removedSubtask.supertask = nil
            }
            
            removedSubtasks.append(removedSubtask)
        }
        
        send(.didRemoveSubtasks(indexes: indexes))
        
        return removedSubtasks
    }
    
    @discardableResult
    func moveSubtask(from: Int, to: Int) -> Bool
    {
        let didMove = subtasks.moveElement(from: from, to: to)
        
        if didMove
        {
            send(.didMoveSubtask(from: from, to: to))
        }
        
        return didMove
    }
    
    // MARK: - Description & Codability
    
    var description: String
    {
        return encode()?.utf8String ?? typeName(of: self)
    }
    
    enum CodingKeys: String, CodingKey
    {
        case title, state, subtasks
    }
    
    // MARK: - Title
    
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
    
    // MARK: - State
    
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
        case inProgress, onHold, done, archived
    }
    
    // MARK: - Supertask
    
    func recoverSupertasks()
    {
        for subtask in subtasks
        {
            subtask.supertask = self
            subtask.recoverSupertasks()
        }
    }
    
    var indexInSupertask: Int?
    {
        return supertask?.index(of: self)
    }
    
    private(set) weak var supertask: Task? = nil
    
    // MARK: - Subtasks
    
    func subtask(at index: Int) -> Task?
    {
        guard subtasks.isValid(index: index) else
        {
            print("Warning: tried to access Task at an out of bound index")
            return nil
        }
        
        return subtasks[index]
    }
    
    func index(of subtask: Task) -> Int?
    {
        return subtasks.index(where: { $0 === subtask })
    }
    
    var hasSubtasks: Bool { return subtasks.count > 0 }
    var numberOfSubtasks: Int { return subtasks.count }
    
    private var subtasks = [Task]()
    
    // MARK: - UUID
    
    var id: String { return String(hash(self)) }
    
    // MARK: - Event
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event
    {
        case didNothing
        
        case didChangeState
        case didChangeTitle
        
        case didMoveSubtask(from: Int, to: Int)
        case didInsertSubtask(index: Int)
        case didRemoveSubtasks(indexes: [Int])
    }
}
