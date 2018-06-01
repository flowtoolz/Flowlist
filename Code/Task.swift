import SwiftObserver
import SwiftyToolz

final class Task: Codable, Observable, Tree
{    
    // MARK: - Codable Data
    
    enum CodingKeys: CodingKey { case title, state, branches }
    
    private(set) var title = Var<String>()
    private(set) var state = Var<TaskState>()
    
    // MARK: - Observable Tree Editing
    
    @discardableResult
    func groupSubtasks(at indexes: [Int]) -> Task?
    {
        guard let groupIndex = indexes.min() else
        {
            log(warning: "Tried to group tasks at no indexes.")
            return nil
        }
        
        let group = Task()
        
        guard let merged = mergeBranches(at: indexes,
                                         as: group,
                                         at: groupIndex) else { return nil }

        send(.didRemove(subtasks: merged, from: indexes))
        send(.didCreate(at: groupIndex))
        group.send(.didInsert(at: Array(0 ..< group.numberOfBranches)))
        
        return group
    }
    
    @discardableResult
    func removeSubtasks(at indexes: [Int]) -> [Task]?
    {
        guard let removedSubtasks = removeBranches(at: indexes) else { return nil }
        
        send(.didRemove(subtasks: removedSubtasks, from: indexes))
        
        return removedSubtasks
    }
    
    @discardableResult
    func insert(_ subtask: Task, at index: Int) -> Task?
    {
        guard insert(branch: subtask, at: index) else { return nil }
        
        send(.didInsert(at: [index]))

        return subtask
    }
    
    @discardableResult
    func insert(_ subtasks: [Task], at index: Int) -> Bool
    {
        guard insert(branches: subtasks, at: index) else { return false }
        
        if !subtasks.isEmpty
        {
            let insertedIndexes = Array(index ..< index + subtasks.count)
        
            send(.didInsert(at: insertedIndexes))
        }
        
        return true
    }
    
    @discardableResult
    func create(at index: Int) -> Task?
    {
        let subtask = Task()
        
        guard insert(branch: subtask, at: index) else { return nil }
        
        send(.didCreate(at: index))
        
        return subtask
    }
    
    @discardableResult
    func moveSubtask(from: Int, to: Int) -> Bool
    {
        guard moveBranch(from: from, to: to) else { return false }
        
        send(.didMove(from: from, to: to))
        
        return true
    }
    
    // MARK: - Tree
    
    weak var root: Task? = nil
    {
        didSet
        {
            guard oldValue !== root else { return }
            
            send(.didChangeRoot(from: oldValue, to: root))
        }
    }
    
    var branches = [Task]()
    
    // MARK: - Observability
    
    var latestUpdate: Edit { return .didNothing }
}
