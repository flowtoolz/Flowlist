import SwiftObserver
import SwiftyToolz

class TaskBrowser: Observer
{
    init() { createTaskLists() }
    
    private func observe(list: SelectableTaskList)
    {
        observe(list.selection, filter: { $0 == .didChange })
        {
            [weak self, weak list] event in
            
            guard let list = list else { return }
            
            self?.listChangedSelection(list)
        }
    }
    
    func moveRight() -> SelectableTaskList
    {
        stopObserving(lists.remove(at: 0))

        return addTaskList()
    }
    
    func moveLeft() -> SelectableTaskList
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
        
        if let slaveContainer = slave.root
        {
            master.selection.removeAll()
            master.selection.add(task: slaveContainer)
        }
    }
    
    private func listChangedSelection(_ list: SelectableTaskList)
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
            slave.set(root: nil)
            return
        }
        
        slave.set(root: container)
    }
    
    func setContainerOfMaster(at index: Int)
    {
        guard index >= 0, index < lists.count - 1 else { return }
        
        let master = lists[index]
        let slave = lists[index + 1]
        
        master.set(root: slave.root?.supertask)
    }
    
    // MARK: Task List View Models
    
    private func createTaskLists()
    {
        lists.removeAll()
        
        for _ in 0 ..< 5 { addTaskList() }
        
        lists[2].set(root: store.root)
    }
    
    @discardableResult
    private func addTaskList(prepend: Bool = false) -> SelectableTaskList
    {
        let list = SelectableTaskList()
        
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
    
    var lists = [SelectableTaskList]()
}
