import SwiftObserver
import SwiftyToolz

class Selection: Observable
{
    // MARK: - Life Cycle
    
    deinit { removeObservers() }
    
    // MARK: - Select Tasks
    
    func setWithTasksListed(at newIndexes: [Int])
    {
        guard let root = root else
        {
            log(error: "Tried to select tasks while selection has no root.")
            return
        }
    
        var changedIndexes = indexes
        
        selectedTasks.removeAll()
        
        for index in newIndexes
        {
            guard let task = root[index] else
            {
                log(error: "Couldn't find task to select at index \(index).")
                continue
            }
            
            selectedTasks[task] = task
            changedIndexes.append(index)
        }
        
        if !changedIndexes.isEmpty
        {
            send(.didChange(atIndexes: changedIndexes))
        }
    }
    
    func toggle(_ task: Task)
    {
        guard let index = root?.index(of: task) else { return }
        
        if isSelected(task)
        {
            selectedTasks[task] = nil
        }
        else
        {
            selectedTasks[task] = task
        }
        
        send(.didChange(atIndexes: [index]))
    }
    
    func set(with task: Task)
    {
        guard let root = root else
        {
            log(error: "Tried to set selection while selection has no root.")
            return
        }
        
        guard !isSelected(task) || selectedTasks.count > 1,
            let index = root.index(of: task)
        else
        {
            return
        }
        
        var changedIndexes = indexes
        changedIndexes.append(index)
        
        selectedTasks = [task : task]
        
        send(.didChange(atIndexes: changedIndexes))
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
            log(error: "Tried to select task while selection has no root.")
            return
        }
        
        guard !isSelected(task), let index = root.index(of: task) else
        {
            log(warning: "Tried invalid selection.")
            return
        }
        
        selectedTasks[task] = task
        
        send(.didChange(atIndexes: [index]))
    }
    
    // MARK: - Deselect Tasks
    
    func remove(tasks: [Task])
    {
        guard let root = root else
        {
            log(error: "Tried to deselect tasks while selection has no root.")
            return
        }
        
        var changedIndexes = [Int]()
        var selectionChanged = false
        
        for task in tasks
        {
            guard isSelected(task) else
            {
                log(warning: "Tried to deselect task that is not selected.")
                continue
            }
            
            selectedTasks[task] = nil
            
            selectionChanged = true
            
            if let index = root.index(of: task)
            {
                changedIndexes.append(index)
            }
        }
        
        if selectionChanged
        {
            send(.didChange(atIndexes: changedIndexes))
        }
    }
    
    func removeTask(at index: Int)
    {
        guard let root = root else
        {
            log(error: "Tried to deselect task at index \(index) while selection has no root.")
            return
        }
        
        guard let task = root[index], isSelected(task) else
        {
            log(warning: "Tried invalid deselection of index \(index).")
            return
        }
        
        selectedTasks[task] = nil
        
        send(.didChange(atIndexes: [index]))
    }
    
    func removeAll()
    {
        guard count > 0 else
        {
            log(warning: "Tried to deselect all selected tasks but none are selected.")
            return
        }
        
        let changedIndexes = indexes
        
        selectedTasks.removeAll()
        
        send(.didChange(atIndexes: changedIndexes))
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
    var tasks: [Task] { return Array(selectedTasks.values) }
    
    private var selectedTasks = [Task : Task]()
    
    // MARK: - Observability
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event { case didNothing, didChange(atIndexes: [Int]) }
}
