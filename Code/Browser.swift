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

class Browser: Observer, Observable
{
    // MARK: - Navigate
    
    func move(_ direction: Direction) -> Bool
    {
        let moveLeft = direction == .left
        let newFocusedIndex = moveLeft ? 1 : 3
        
        guard lists[newFocusedIndex].root != nil else { return false }
        
        let removalIndex = moveLeft ? lists.count - 1 : 0
        
        observeSelection(in: lists.remove(at: removalIndex), start: false)
        
        let newList = addTaskList(prepend: moveLeft)
        
        defer { send(.didMove(direction: direction)) }
        
        if moveLeft
        {
            guard lists.count > 1,
                let sublistRoot = lists[1].root,
                let firstRoot = sublistRoot.supertask else { return true }
            
            newList.set(root: firstRoot)
            newList.selection.set(with: sublistRoot)
        }
        else
        {
            updateRootOfList(at: lists.count - 1)
            
            lists[2].select()
        }
        
        return true
    }
    
    // MARK: - Create Task Lists
    
    init()
    {
        for _ in 0 ..< 5 { addTaskList() }
        
        lists[2].set(root: store.root)
        lists[2].select()
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
        let list = lists[index]
        
        if newRoot !== list.root { list.set(root: newRoot) }
    }
    
    func list(at index: Int) -> SelectableList?
    {
        guard lists.isValid(index: index) else { return nil }
        
        return lists[index]
    }
    
    var numberOfLists: Int { return lists.count }
    
    private var lists = [SelectableList]()
    
    // MARK: - Observability
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event { case didNothing, didMove(direction: Direction) }
}

enum Direction
{
    case left, right
    
    var reverse: Direction { return self == .left ? .right : .left }
}
