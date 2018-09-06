import SwiftObserver
import SwiftyToolz

class Selection: Observable
{
    // MARK: - Life Cycle
    
    deinit { removeObservers() }
    
    // MARK: - Select Tasks
    
    func setWithTasksListed(at indexes: [Int])
    {
        guard let root = root else
        {
            log(warning: "Tried to select tasks while selection has no root.")
            return
        }
        
        guard indexes.sorted() != self.indexes else
        {
            log(warning: "Tried to select the same tasks again: \(indexes)")
            return
        }
    
        selectedTasks.removeAll()
        
        for index in indexes
        {
            if let task = root[index]
            {
                selectedTasks[task] = task
            }
            else
            {
                log(error: "Couldn't find task to select at index \(index).")
            }
        }
        
        send(.didChange)
    }
    
    func toggle(_ task: Task)
    {
        if isSelected(task)
        {
            selectedTasks[task] = nil
        }
        else
        {
            selectedTasks[task] = task
        }
        
        send(.didChange)
    }
    
    func set(with task: Task)
    {
        guard let root = root else
        {
            log(error: "Tried to set selection while selection has no root.")
            return
        }
        
        guard let _ = root.index(of: task),
            !isSelected(task) || selectedTasks.count > 1
        else
        {
            return
        }
        
        selectedTasks = [task : task]
        
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
        
        selectedTasks[task] = task
        
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
            
            selectedTasks[task] = nil
            
            didChange = true
        }
        
        if didChange { send(.didChange) }
    }
    
    func removeTask(at index: Int)
    {
        guard let task = root?[index], isSelected(task) else
        {
            log(warning: "Tried invalid deselection of index \(index).")
            return
        }
        
        selectedTasks[task] = nil
        
        send(.didChange)
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
    
    var indexes: [Int]
    {
        var result = [Int]()
        
        for index in 0 ..< (root?.numberOfBranches ?? 0)
        {
            if let task = root?[index], isSelected(task)
            {
                result.append(index)
            }
        }
        
        return result
    }
    
    weak var root: Task?
    {
        didSet
        {
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
    
    var description: String
    {
        var desc = ""
        
        for task in selectedTasks.values
        {
            desc += task.title.value ?? "untitled"
            desc += ", "
        }
        
        return desc
    }
    
    func isSelected(_ task: Task?) -> Bool
    {
        guard let task = task else { return false }
        
        return selectedTasks[task] === task
    }
    
    var count: Int { return selectedTasks.count }
    var someTask: Task? { return selectedTasks.values.first }
    
    private var selectedTasks = [Task : Task]()
    
    // MARK: - Observability
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event: String { case didNothing, didChange }
}
