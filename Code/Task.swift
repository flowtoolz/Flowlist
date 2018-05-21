import SwiftObserver
import SwiftyToolz

class Task: Codable, Observable
{
    // MARK: - Data
    
    enum CodingKeys: CodingKey { case title, state, subtasks }
    
    private(set) var title = Var<String>()
    
    private(set) var state = Var<State>()
    
    enum State: Int, Codable
    {
        case inProgress, onHold, done, archived
    }
    
    // MARK: - Edit Subtask List
    
    @discardableResult
    func groupSubtasks(at indexes: [Int]) -> Task?
    {
        guard let groupIndex = indexes.min(),
            subtasks.isValid(index: groupIndex),
            subtasks.isValid(index: indexes.max())
        else
        {
            return nil
        }
        
        let removedTasks = removeSubtasks(at: indexes)
        
        guard let group = insert(Task(), at: groupIndex) else
        {
            fatalError("Could not insert group at valid index \(groupIndex).")
        }
        
        for removedTask in removedTasks
        {
            group.insert(removedTask, at: group.numberOfSubtasks)
        }
       
        return group
    }
    
    @discardableResult
    func removeSubtasks(at indexes: [Int]) -> [Task]
    {
        var sortedIndexes = indexes.sorted()
        
        guard subtasks.isValid(index: sortedIndexes.first),
            subtasks.isValid(index: sortedIndexes.last)
            else
        {
            log(warning: "Tried to remove subtasks from at least one out of bound index in \(indexes).")
            return []
        }
        
        var removedSubtasks = [Task]()
        
        while let indexToRemove = sortedIndexes.popLast()
        {
            let removedSubtask = subtasks.remove(at: indexToRemove)
        
            removedSubtask.supertask = nil
            
            removedSubtasks.insert(removedSubtask, at: 0)
        }
        
        send(.didRemove(subtasks: removedSubtasks, from: indexes))
        
        return removedSubtasks
    }
    
    @discardableResult
    func insert(_ subtask: Task, at index: Int) -> Task?
    {
        guard index >= 0, index <= subtasks.count else
        {
            log(warning: "Tried to insert subask at out of bound index \(index).")
            return nil
        }
        
        subtasks.insert(subtask, at: index)
        
        subtask.supertask = self
        
        send(.didInsert(at: [index]))
        
        //print("task \(title.value ?? "unfiltered") inserted subtask at \(index)")
        
        return subtask
    }
    
    @discardableResult
    func moveSubtask(from: Int, to: Int) -> Bool
    {
        guard subtasks.moveElement(from: from, to: to) else { return false }
        
        send(.didMove(from: from, to: to))
        
        return true
    }
    
    // MARK: - Subtasks
    
    func subtask(at index: Int?) -> Task?
    {
        guard let index = index else { return nil }
        
        guard subtasks.isValid(index: index) else
        {
            log(warning: "Tried to access subask at out of bound index \(index).")
            return nil
        }
        
        return subtasks[index]
    }
    
    func index(of subtask: Task) -> Int?
    {
        return subtasks.index { $0 === subtask }
    }
    
    var hasSubtasks: Bool { return subtasks.count > 0 }
    var numberOfSubtasks: Int { return subtasks.count }
    
    private var subtasks = [Task]()
    
    // MARK: - Supertask
    
    func recoverSupertasks()
    {
        for subtask in subtasks
        {
            subtask.supertask = self
            subtask.recoverSupertasks()
        }
    }
    
    private(set) weak var supertask: Task? = nil
    
    // MARK: - Observability
    
    var latestUpdate: SubtaskChange { return .didNothing }
    
    enum SubtaskChange
    {
        case didNothing
        case didMove(from: Int, to: Int)
        case didInsert(at: [Int])
        case didRemove(subtasks: [Task], from: [Int])
        
        var itemsDidChange: Bool
        {
            switch self
            {
            case .didRemove, .didInsert: return true
            default: return false
            }
        }
    }
}
