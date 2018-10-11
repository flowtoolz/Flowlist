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
    
    func toggle(_ task: Item)
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
    
    func add(task: Item?)
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
    
    func remove(tasks: [Item])
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
            
    // MARK: - Root
    
    var indexes: [Int]
    {
        var result = [Int]()
        
        for index in 0 ..< (root?.count ?? 0)
        {
            if let task = root?[index], isSelected(task)
            {
                result.append(index)
            }
        }
        
        return result
    }
    
    weak var root: Item?
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
            desc += task.data?.title.value ?? "untitled"
            desc += ", "
        }
        
        return desc
    }
    
    func isSelected(_ task: Item?) -> Bool
    {
        guard let task = task else { return false }
        
        return selectedTasks[task] === task
    }
    
    var count: Int { return selectedTasks.count }
    var someTask: Item? { return selectedTasks.values.first }
    var tasks: [Item] { return Array(selectedTasks.values) }
    
    private var selectedTasks = [Item : Item]()
    
    // MARK: - Observability
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event { case didNothing, didChange(atIndexes: [Int]) }
}
