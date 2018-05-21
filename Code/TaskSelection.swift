import SwiftObserver
import SwiftyToolz

class TaskSelection: Observable
{
    // MARK: - Select Tasks
    
    func setWithTasksListed(at indexes: [Int])
    {
        guard let supertask = supertask else
        {
            log(warning: "Tried to select tasks while selection has no supertask.")
            return
        }
        
        if indexes.isEmpty && selectedTasks.isEmpty { return }
        
        var didChange = false
        var didClear = count == 0
        
        for index in indexes
        {
            if let task = supertask.subtask(at: index)
            {
                if !didClear
                {
                    selectedTasks.removeAll()
                    didClear = true
                }
    
                selectedTasks[task.hash] = task
    
                didChange = true
            }
            else
            {
                log(warning: "Tried to select unlisted task.")
            }
        }
        
        if didChange { send(.didChange) }
    }
    
    func add(task: Task?)
    {
        guard let task = task else { return }
        
        guard let _ = supertask?.index(of: task), !isSelected(task) else
        {
            log(warning: "Tried invalid selection.")
            return
        }
        
        selectedTasks[task.hash] = task
        
        send(.didChange)
    }
    
    // MARK: - Deselect Tasks
    
    func remove(tasks: [Task])
    {
        var didChange = false
        
        for task in tasks
        {
            guard isSelected(task) else
            {
                log(warning: "Tried to deselect task that is not selected.")
                continue
            }
            
            selectedTasks[task.hash] = nil
            
            didChange = true
        }
        
        if didChange { send(.didChange) }
    }
    
    func removeAll()
    {
        guard count > 0 else
        {
            log(warning: "Tried to deselect all selected tasks but none are selected.")
            return
        }
        
        selectedTasks.removeAll()
        
        send(.didChange)
    }
    
    // MARK: - Supertask
    
    weak var supertask: Task?
    {
        didSet
        {
            //print("selection gets new supertask \(supertask?.title.value ?? "untitled")")
            
            guard oldValue !== supertask else
            {
                log(warning: "Tried to set identical supertask in selection.")
                return
            }
                
            guard count > 0 else { return }
            
            selectedTasks.removeAll()
            
            send(.didChange)
        }
    }
    
    // MARK: - Selected Tasks
    
    func isSelected(_ task: Task) -> Bool
    {
        return selectedTasks[task.hash] === task
    }
    
    var description: String
    {
        return selectedTasks.description
    }
    
    var count: Int { return selectedTasks.count }
    var first: Task? { return selectedTasks.values.first }
    
    private var selectedTasks = [HashValue : Task]()
    
    // MARK: - Observability
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event: String { case didNothing, didChange }
}
