import SwiftObserver
import SwiftyToolz

class MainViewModel: Observer
{
    init() { createTaskLists() }
    
    private func observe(list: TaskListViewModel)
    {
        observe(list.selection, filter: { $0 == .didChange })
        {
            [weak self, weak list] event in
            
            guard let list = list else { return }
            
            self?.listChangedSelection(list)
        }
    }
    
    func moveRight() -> TaskListViewModel
    {
        stopObserving(lists.remove(at: 0))

        return addTaskList()
    }
    
    func moveLeft() -> TaskListViewModel
    {
        stopObserving(lists.popLast())
        
        return addTaskList(prepend: true)
    }
    
    func selectSlaveInMaster(at index: Int)
    {
        guard index >= 0, index + 1 < lists.count else { return }
        
        let master = lists[index]
        
        guard master.numberOfTasks > 0 else { return }
        
        let slave = lists[index + 1]
        
        if let slaveContainer = slave.supertask
        {
            master.selection.removeAll()
            master.selection.add(slaveContainer)
        }
    }
    
    private func listChangedSelection(_ list: TaskListViewModel)
    {
        guard let index = lists.index(where: { $0 === list }) else
        {
            log(warning: "Unknown TaskList changed selection.")
            return
        }
        
        setContainerOfSlave(at: index + 1)
    }
    
    func setContainerOfLastList()
    {
        guard lists.count > 0 else { return }
        
        setContainerOfSlave(at: lists.count - 1)
    }
    
    func setContainerOfSlave(at index: Int)
    {
        guard index > 0, index < lists.count else { return }
        
        let slave = lists[index]
        let master = lists[index - 1]
        
        guard master.selection.count == 1,
            let container = master.selection.first
        else
        {
            slave.set(supertask: nil)
            return
        }
        
        slave.set(supertask: container)
    }
    
    func setContainerOfMaster(at index: Int)
    {
        guard index >= 0, index < lists.count - 1 else { return }
        
        let master = lists[index]
        let slave = lists[index + 1]
        
        master.set(supertask: slave.supertask?.supertask)
    }
    
    // MARK: Task List View Models
    
    private func createTaskLists()
    {
        lists.removeAll()
        
        for _ in 0 ..< 5 { addTaskList() }
        
        lists[2].set(supertask: store.root)
    }
    
    @discardableResult
    private func addTaskList(prepend: Bool = false) -> TaskListViewModel
    {
        let list = TaskListViewModel()
        
        observe(list: list)
        
        if prepend
        {
            lists.insert(list, at: 0)
        }
        else
        {
            lists.append(list)
        }
        
        return list
    }
    
    var lists = [TaskListViewModel]()
}
