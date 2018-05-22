import SwiftObserver
import SwiftyToolz

class TaskBrowser: Observer
{
    // MARK: - Navigate
    
    func moveRight() -> SelectableTaskList
    {
        observeSelection(in: lists.remove(at: 0), start: false)
        
        let newLastList = addTaskList()
        
        updateRootOfList(at: lists.count - 1)
        
        return newLastList
    }
    
    func moveLeft() -> SelectableTaskList
    {
        observeSelection(in: lists.popLast(), start: false)
        
        let newFirstList = addTaskList(prepend: true)

        updateNewFirstList()
        
        return newFirstList
    }
    
    private func updateNewFirstList()
    {
        guard lists.count > 1 else { return }
        
        let list = lists[0]
        let sublistRoot = lists[1].root
        
        list.set(root: sublistRoot?.supertask)
        
        if let sublistRoot = sublistRoot, list.numberOfTasks > 0
        {
            // FIXME: add functo to selection that allows to set selection with task
            list.selection.removeAll()
            list.selection.add(task: sublistRoot)
        }
    }
    
    // MARK: - Create Task Lists
    
    init()
    {
        for _ in 0 ..< 5 { addTaskList() }
        
        lists[2].set(root: store.root)
    }
    
    @discardableResult
    private func addTaskList(prepend: Bool = false) -> SelectableTaskList
    {
        let list = SelectableTaskList()
        
        observeSelection(in: list)
        
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
    
    // MARK: - Observe Selections in Lists
    
    private func observeSelection(in list: SelectableTaskList?,
                                  start: Bool = true)
    {
        guard let list = list else
        {
            log(warning: "Tried to \(start ? "start" : "stop") observing selection of nil list.")
            stopObservingDeadObservables()
            return
        }
        
        guard start else
        {
            stopObserving(list.selection)
            return
        }
        
        observe(list.selection, filter: { $0 == .didChange })
        {
            [weak self, weak list] event in
            
            guard let list = list else { return }
            
            self?.listChangedSelection(list)
        }
    }
    
    private func listChangedSelection(_ list: SelectableTaskList)
    {
        guard let index = lists.index(where: { $0 === list }) else
        {
            log(error: "Received update from unmanaged list.")
            return
        }
        
        updateRootOfList(at: index + 1)
    }
    
    // MARK: - Lists
    
    private func updateRootOfList(at index: Int)
    {
        guard index > 0, index < lists.count else
        {
            log(warning: "Tried to update root of list at invaid index \(index).")
            return
        }
        
        let superSelection = lists[index - 1].selection
        let newRoot = superSelection.count == 1 ? superSelection.first : nil
        
        lists[index].set(root: newRoot)
    }
    
    func list(at index: Int) -> SelectableTaskList?
    {
        guard lists.isValid(index: index) else { return nil }
        
        return lists[index]
    }
    
    var numberOfLists: Int { return lists.count }
    
    private var lists = [SelectableTaskList]()
}
