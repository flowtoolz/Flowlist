import SwiftObserver
import SwiftyToolz

class Task: Codable, Observable
{
    // MARK: - Initialization
    
    convenience init(title: String? = nil,
                     state: State? = nil)
    {
        self.init()
        
        self.title <- title
        self.state <- state
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
    
    // MARK: - Data
    
    private(set) var title = Var<String>()
    
    var isDone: Bool { return state.value == .done }
    
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
            print("Warning: tried to remove tasks with at least one out of bound index")
            return []
        }
        
        var removedSubtasks = [Task]()
        
        while let indexToRemove = sortedIndexes.popLast()
        {
            let removedSubtask = subtasks.remove(at: indexToRemove)
        
            removedSubtask.supertask = nil
            
            removedSubtasks.insert(removedSubtask, at: 0)
        }
        
        send(.didRemoveItems(indexes: indexes))
        
        return removedSubtasks
    }
    
    @discardableResult
    func insert(_ subtask: Task, at index: Int) -> Task?
    {
        guard index >= 0, index <= subtasks.count else
        {
            print("Warning: tried to insert Task at an out of bound index into another task")
            return nil
        }
        
        subtasks.insert(subtask, at: index)
        
        subtask.supertask = self
        
        send(.didInsertItem(index: index))
        
        return subtask
    }
    
    @discardableResult
    func moveSubtask(from: Int, to: Int) -> Bool
    {
        let didMove = subtasks.moveElement(from: from, to: to)
        
        if didMove
        {
            send(.didMoveItem(from: from, to: to))
        }
        
        return didMove
    }
    
    var latestUpdate: ListEditingEvent { return .didNothing }
    
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
    
    var indexInSupertask: Int?
    {
        return supertask?.index(of: self)
    }
    
    private(set) weak var supertask: Task? = nil
}
