import SwiftObserver
import SwiftyToolz

extension Browser
{
    var description: String
    {
        var desc = ""
        
        for i in 0 ..< lists.count
        {
            let list = lists[i]
            desc += "\(i): "
            desc += list.title.observable?.value ?? "untitled"
            desc += "\n"
        }
        
        return desc
    }
}

class Browser: Observer
{
    // MARK: - Navigate
    
    func moveRight() -> SelectableList
    {
        observeSelection(in: lists.remove(at: 0), start: false)
        
        let newLastList = addTaskList()
        
        updateRootOfList(at: lists.count - 1)
        
        return newLastList
    }
    
    func moveLeft() -> SelectableList
    {
        observeSelection(in: lists.popLast(), start: false)
        
        let firstList = addTaskList(prepend: true)

        guard lists.count > 1,
            let sublistRoot = lists[1].root,
            let firstRoot = sublistRoot.supertask else { return firstList }

        firstList.set(root: firstRoot)
        firstList.selection.set(with: sublistRoot)
        
        return firstList
    }
    
    // MARK: - Create Task Lists
    
    init()
    {
        for _ in 0 ..< 5 { addTaskList() }
        
        lists[2].set(root: store.root)
    }
    
    @discardableResult
    private func addTaskList(prepend: Bool = false) -> SelectableList
    {
        let list = SelectableList()
        
        observeSelection(in: list)
        
        lists.insert(list, at: prepend ? 0 : lists.count)
        
        return list
    }
    
    // MARK: - Observe Selections in Lists
    
    private func observeSelection(in list: SelectableList?,
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
        
        observe(list.selection, select: .didChange)
        {
            [weak self, weak list] in
            
            guard let list = list else { return }
            
            self?.listChangedSelection(list)
        }
    }
    
    private func listChangedSelection(_ list: SelectableList)
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
    
    func list(at index: Int) -> SelectableList?
    {
        guard lists.isValid(index: index) else { return nil }
        
        return lists[index]
    }
    
    var numberOfLists: Int { return lists.count }
    
    private var lists = [SelectableList]()
}
