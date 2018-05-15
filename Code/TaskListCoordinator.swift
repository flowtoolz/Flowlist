import SwiftObserver

let listCoordinator = TaskListCoordinator()

class TaskListCoordinator: Observer
{
    fileprivate init()
    {
        lists[2].container = store.root
        
        for list in lists
        {
            observe(list: list)
        }
    }
    
    private func observe(list: TaskListViewModel)
    {
        observe(list)
        {
            [weak self, weak list] event in
            
            guard let list = list else { return }
            
            switch(event)
            {
            case .didNothing: break
            case .didChangeSelection: self?.listChangedSelection(list)
            }
        }
    }
    
    func moveRight() -> TaskListViewModel
    {
        lists.remove(at: 0)
        
        let newList = TaskListViewModel()
        lists.append(newList)
        
        return newList
    }
    
    func moveLeft() -> TaskListViewModel
    {
        _ = lists.popLast()
        
        let newList = TaskListViewModel()
        
        lists.insert(newList, at: 0)
        
        return newList
    }
    
    func selectSlaveInMaster(at index: Int)
    {
        guard index >= 0, index + 1 < lists.count else
        {
            return
        }
        
        let master = lists[index]
        
        guard master.container?.hasSubtasks ?? false else
        {
            return
        }
        
        let slave = lists[index + 1]
        
        if let slaveContainer = slave.container
        {
            master.selectedTasks = [slaveContainer.hash : slaveContainer]
        }
    }
    
    private func listChangedSelection(_ list: TaskListViewModel)
    {
        guard let index = lists.index(where: { $0 === list }) else
        {
            print("Warning: unknown TaskList changed selection.")
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
        guard index > 0, index < lists.count else
        {
            return
        }
        
        let slave = lists[index]
        let master = lists[index - 1]
        
        guard master.selectedTasks.count == 1,
            let container = master.selectedTasks.values.first
        else
        {
            slave.container = nil
            return
        }
        
        slave.container = container
    }
    
    func setContainerOfMaster(at index: Int)
    {
        guard index >= 0, index < lists.count - 1 else
        {
            return
        }
        
        let master = lists[index]
        let slave = lists[index + 1]
        
        master.container = slave.container?.supertask
    }
    
    var lists = [TaskListViewModel(),
                 TaskListViewModel(),
                 TaskListViewModel(),
                 TaskListViewModel(),
                 TaskListViewModel()]
}
