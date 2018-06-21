import SwiftObserver
import SwiftyToolz

final class Task: Codable, Observable, Tree
{
    // MARK: - Life Cycle
    
    convenience init(title: String? = nil,
                     state: TaskState? = nil,
                     root: Task? = nil)
    {
        self.init()
        
        self.title = Var(title)
        self.state = Var(state)
        self.root = root
    }
    
    init() { Task.numberOfTasks += 1 }
    
    deinit
    {
        removeObservers()
        
        Task.numberOfTasks -= 1
    }
    
    static var numberOfTasks: Int = 0
    
    // MARK: - Codable Data

    enum CodingKeys: String, CodingKey
    {
        case title, state, branches = "subtasks"
    }
    
    private(set) var title = Var<String>()
    private(set) var state = Var<TaskState>()
    
    // MARK: - Group
    
    @discardableResult
    func groupSubtasks(at indexes: [Int]) -> Task?
    {
        guard let groupIndex = indexes.min() else
        {
            log(warning: "Tried to group tasks at no indexes.")
            return nil
        }
        
        let group = Task(state: highestPriorityState(at: indexes))
        
        guard let merged = mergeBranches(at: indexes,
                                         as: group,
                                         at: groupIndex) else { return nil }

        send(.did(.remove(subtasks: merged, from: indexes)))
        send(.did(.create(at: groupIndex)))
        
        let insertedIndexesInGroup = Array(0 ..< group.numberOfBranches)
        group.send(.did(.insert(at: insertedIndexesInGroup)))
        
        return group
    }
    
    private func highestPriorityState(at indexes: [Int]) -> TaskState?
    {
        var highestPriorityState: TaskState? = .trashed
        
        for index in indexes
        {
            guard let subtask = self[index] else { continue }
            
            let subtaskState = subtask.state.value
            let subtaskPriority = TaskState.priority(of: subtaskState)
            let highestPriority = TaskState.priority(of: highestPriorityState)
            
            if subtaskPriority < highestPriority
            {
                highestPriorityState = subtaskState
            }
        }
        
        return highestPriorityState
    }
    
    // MARK: - Remove
    
    @discardableResult
    func removeSubtasks(at indexes: [Int]) -> [Task]?
    {
        guard let removedSubtasks = removeBranches(at: indexes) else { return nil }
        
        send(.did(.remove(subtasks: removedSubtasks, from: indexes)))
        
        lastRemoved.storeCopies(of: removedSubtasks)
        
        return removedSubtasks
    }
    
    func insertLastRemoved(at index: Int) -> Int
    {
        let lastRemovedObjects = lastRemoved.copiesOfStoredObjects
        
        guard lastRemovedObjects.count > 0,
            insert(lastRemovedObjects, at: index) else { return 0 }
        
        lastRemoved.storeCopies(of: [])
        
        return lastRemovedObjects.count
    }
    
    var numberOfRemovedSubtasks: Int { return lastRemoved.count }

    private let lastRemoved = Clipboard<Task>()
    
    // MARK: - Insert
    
    @discardableResult
    func insert(_ subtask: Task, at index: Int) -> Task?
    {
        guard insert(branch: subtask, at: index) else { return nil }
        
        send(.did(.insert(at: [index])))

        return subtask
    }
    
    @discardableResult
    func insert(_ subtasks: [Task], at index: Int) -> Bool
    {
        guard insert(branches: subtasks, at: index) else { return false }
        
        if !subtasks.isEmpty
        {
            let insertedIndexes = Array(index ..< index + subtasks.count)
        
            send(.did(.insert(at: insertedIndexes)))
        }
        
        return true
    }
    
    // MARK: - Create
    
    @discardableResult
    func create(at index: Int) -> Task?
    {
        let taskBelowIsInProgress = self[index]?.state.value == .inProgress
        
        let newSubtask = Task(state: taskBelowIsInProgress ? .inProgress : nil)
        
        guard insert(branch: newSubtask, at: index) else { return nil }
        
        send(.did(.create(at: index)))
        
        return newSubtask
    }
    
    // MARK: - Move
    
    @discardableResult
    func moveSubtask(from: Int, to: Int) -> Bool
    {
        guard moveBranch(from: from, to: to) else { return false }
        
        send(.did(.move(from: from, to: to)))
        
        return true
    }
    
    // MARK: - Tree
    
    weak var root: Task? = nil
    {
        didSet
        {
            guard oldValue !== root else { return }
            
            send(.did(.changeRoot(from: oldValue, to: root)))
        }
    }
    
    var branches = [Task]()
    
    // MARK: - Observability
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event { case didNothing, did(Edit) }
}
