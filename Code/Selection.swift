import SwiftObserver
import SwiftyToolz

class Selection: Observable
{
    // MARK: - Select Tasks
    
    func setWithTasksListed(at indexes: [Int])
    {
        guard let root = root else
        {
            log(warning: "Tried to select tasks while selection has no root.")
            return
        }
        
        if indexes.isEmpty && selectedTasks.isEmpty { return }
        
        var didChange = false
        var didClear = count == 0
        
        for index in indexes
        {
            if let task = root.subtask(at: index)
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
    
    func set(with task: Task)
    {
        guard let root = root else
        {
            log(warning: "Tried to select tasks while selection has no root.")
            return
        }
        
        guard let _ = root.index(of: task), !isSelected(task) else
        {
            log(warning: "Tried invalid selection.")
            return
        }
        
        selectedTasks = [task.hash : task]
        
        send(.didChange)
    }
    
    func add(task: Task?)
    {
        guard let task = task else
        {
            log(warning: "Tried to select nil task.")
            return
        }
        
        guard let root = root else
        {
            log(warning: "Tried to select task while selection has no root.")
            return
        }
        
        guard let _ = root.index(of: task), !isSelected(task) else
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
    
    // MARK: - Root
    
    weak var root: Task?
    {
        didSet
        {
            //print("selection gets new root \(root?.title.value ?? "untitled")")
            
            guard oldValue !== root else
            {
                log(warning: "Tried to set identical root in selection.")
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
