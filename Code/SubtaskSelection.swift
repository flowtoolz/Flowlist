import SwiftObserver
import SwiftyToolz

class SubtaskSelection: Observable
{
    // MARK: - Edit Selection
    
    func removeSubtasks(at indexes: [Int])
    {
        var didChange = false

        for index in indexes
        {
            guard let subtask = task?.subtask(at: index),
                isSelected(subtask)
            else
            {
                continue
            }
            
            selectedSubtasks[subtask.hash] = nil
            didChange = true
        }
        
        if didChange { send(.didChange) }
    }
    
    func setSubtasks(at indexes: [Int])
    {
        if indexes.isEmpty && selectedSubtasks.isEmpty { return }
        
        selectedSubtasks.removeAll()
        
        for index in indexes
        {
            if let subtask = task?.subtask(at: index)
            {
                selectedSubtasks[subtask.hash] = subtask
            }
        }
        
        send(.didChange)
    }
    
    func add(_ subtask: Task)
    {
        guard isSubtask(subtask), !isSelected(subtask) else { return }
        
        selectedSubtasks[subtask.hash] = subtask
        
        send(.didChange)
    }
    
    func remove(_ subtask: Task)
    {
        guard isSelected(subtask) else { return }
        
        selectedSubtasks[subtask.hash] = nil
        
        send(.didChange)
    }
    
    func removeAll()
    {
        guard count > 0 else { return }
        
        selectedSubtasks.removeAll()
        
        send(.didChange)
    }
    
    // MARK: - Root Task
    
    var indexes: [Int]
    {
        var result = [Int]()
        
        for index in 0 ..< (task?.numberOfSubtasks ?? 0)
        {
            if let subtask = task?.subtask(at: index),
                selectedSubtasks[subtask.hash] != nil
            {
                result.append(index)
            }
        }
        
        return result
    }
    
    private func isSubtask(_ subtask: Task) -> Bool
    {
        return task?.index(of: subtask) != nil
    }
    
    weak var task: Task?
    {
        didSet
        {
            guard oldValue !== task, count > 0 else { return }

            selectedSubtasks.removeAll()
            
            send(.didChange)
        }
    }
    
    // MARK: - Selected Subtasks
    
    var count: Int { return selectedSubtasks.count }
    var first: Task? { return selectedSubtasks.values.first }
    
    private func isSelected(_ subtask: Task) -> Bool
    {
        return selectedSubtasks[subtask.hash] === subtask
    }
    
    private var selectedSubtasks = [HashValue : Task]()
    
    // MARK: - Observability
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event: String { case didNothing, didChange }
}
