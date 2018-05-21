import SwiftObserver
import SwiftyToolz

extension TaskSelection
{
    var description: String
    {
        return selectedTasks.description
    }
}

class TaskSelection: Observable
{
    // MARK: - Select Tasks
    
    func setWithTasksListed(at indexes: [Int])
    {
        if indexes.isEmpty && selectedTasks.isEmpty { return }
        
        var didChange = false
        var didClear = count == 0
        
        for index in indexes
        {
            if let task = supertask?.subtask(at: index)
            {
                if !didClear
                {
                    selectedTasks.removeAll()
                    didClear = true
                }
    
                selectedTasks[task.hash] = task
    
                didChange = true
            }
        }
        
        if didChange { send(.didChange) }
    }
    
    func add(task: Task?)
    {
        guard let task = task,
            supertask?.index(of: task) != nil,
            !isSelected(task) else { return }
        
        selectedTasks[task.hash] = task
        
        send(.didChange)
    }
    
    // MARK: - Deselect Tasks
    
    func remove(tasks: [Task])
    {
        var didChange = false
        
        for task in tasks
        {
            guard isSelected(task) else { continue }
            
            selectedTasks[task.hash] = nil
            
            didChange = true
        }
        
        if didChange { send(.didChange) }
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
            if let task = supertask?.subtask(at: index), isSelected(task)
            {
                result.append(index)
            }
        }
        
        return result
    }
    
    weak var supertask: Task?
    {
        didSet
        {
            //print("selection gets new supertask \(supertask?.title.value ?? "untitled")")
            
            guard oldValue !== supertask, count > 0 else { return }
            
            selectedTasks.removeAll()
            
            send(.didChange)
        }
    }
    
    // MARK: - Selected Tasks
    
    var count: Int { return selectedTasks.count }
    var first: Task? { return selectedTasks.values.first }
    
    func isSelected(_ task: Task) -> Bool
    {
        return selectedTasks[task.hash] === task
    }
    
    private var selectedTasks = [HashValue : Task]()
    
    // MARK: - Observability
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event: String { case didNothing, didChange }
}
