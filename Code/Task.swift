import SwiftObserver
import SwiftyToolz

final class Task: Codable, Observable, Tree
{
    // MARK: - Initialization
    
    convenience init(_ title: String)
    {
        self.init()
        self.title <- title
    }
    
    // MARK: - Data
    
    enum CodingKeys: CodingKey { case title, state, branches }
    
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
            branches.isValid(index: groupIndex),
            branches.isValid(index: indexes.max())
        else
        {
            log(warning: "Tried to group invalid indexes \(indexes).")
            return nil
        }
        
        let removedTasks = removeSubtasks(at: indexes)
        
        guard let group = create(at: groupIndex) else
        {
            log(error: "Could not create group at valid index \(groupIndex).")
            return nil
        }
        
        for removedTask in removedTasks
        {
            group.insert(removedTask, at: group.numberOfBranches)
        }
       
        return group
    }
    
    @discardableResult
    func removeSubtasks(at indexes: [Int]) -> [Task]
    {
        let removedSubtasks = removeBranches(at: indexes)
        
        if !removedSubtasks.isEmpty
        {
            send(.didRemove(subtasks: removedSubtasks, from: indexes))
        }
        
        return removedSubtasks
    }
    
    @discardableResult
    func insert(_ subtask: Task, at index: Int) -> Task?
    {
        guard insert(branch: subtask, at: index) else { return nil }
        
        send(.didInsert(at: [index]))
        
        //print("task \(title.value ?? "unfiltered") inserted subtask at \(index)")
        
        return subtask
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
    
    var branches = [Task]()
    
    // MARK: - Observability
    
    var latestUpdate: ListEdit { return .didNothing }
}
