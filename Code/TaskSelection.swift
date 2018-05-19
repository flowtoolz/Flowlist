import SwiftObserver
import SwiftyToolz

class TaskSelection: Observable
{
    // MARK: - Edit Selection
    
    func removeTasks(at indexes: [Int])
    {
        var didChange = false

        for index in indexes
        {
            guard let task = supertask?.subtask(at: index),
                isSelected(task)
            else
            {
                continue
            }
            
            selectedTasks[task.hash] = nil
            didChange = true
        }
        
        if didChange { send(.didChange) }
    }
    
    func setTasks(at indexes: [Int])
    {
        if indexes.isEmpty && selectedTasks.isEmpty { return }
        
        selectedTasks.removeAll()
        
        for index in indexes
        {
            if let task = supertask?.subtask(at: index)
            {
                selectedTasks[task.hash] = task
            }
        }
        
        send(.didChange)
    }
    
    func add(_ task: Task)
    {
        guard isTask(task), !isSelected(task) else { return }
        
        selectedTasks[task.hash] = task
        
        send(.didChange)
    }
    
    func remove(_ task: Task)
    {
        guard isSelected(task) else { return }
        
        selectedTasks[task.hash] = nil
        
        send(.didChange)
    }
    
    func removeAll()
    {
        guard count > 0 else { return }
        
        selectedTasks.removeAll()
        
        send(.didChange)
    }
    
    // MARK: - Supertask
    
    var indexes: [Int]
    {
        var result = [Int]()
        
        for index in 0 ..< (supertask?.numberOfSubtasks ?? 0)
        {
            if let task = supertask?.subtask(at: index),
                selectedTasks[task.hash] != nil
            {
                result.append(index)
            }
        }
        
        return result
    }
    
    private func isTask(_ task: Task) -> Bool
    {
        return supertask?.index(of: task) != nil
    }
    
    weak var supertask: Task?
    {
        didSet
        {
            guard oldValue !== supertask, count > 0 else { return }

            selectedTasks.removeAll()
            
            send(.didChange)
        }
    }
    
    // MARK: - Selected Tasks
    
    var count: Int { return selectedTasks.count }
    var first: Task? { return selectedTasks.values.first }
    
    private func isSelected(_ task: Task) -> Bool
    {
        return selectedTasks[task.hash] === task
    }
    
    private var selectedTasks = [HashValue : Task]()
    
    // MARK: - Observability
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event: String { case didNothing, didChange }
}
