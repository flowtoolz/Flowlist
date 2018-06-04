import SwiftObserver
import SwiftyToolz

class Browser: Observer, Observable
{
    // MARK: - Life Cycle
    
    init()
    {
        for _ in 0 ..< 5 { addTaskList() }
        
        guard lists.isValid(index: focusedListIndex) else { fatalError() }
        
        focusedList.set(root: store.root)
        focusedList.select()
        
        Browser.active = self
    }
    
    static var active: Browser?
    
    deinit { stopAllObserving() }
    
    // MARK: - Navigation
    
    func move(_ direction: Direction)
    {
        guard canMove(direction) else { return }
        
        let moveLeft = direction == .left
        let removalIndex = moveLeft ? lists.count - 1 : 0
        
        observeSelection(in: lists.remove(at: removalIndex), start: false)
        
        let newList = addTaskList(prepend: moveLeft)
        
        defer { send(.didMove(direction: direction)) }
        
        if moveLeft
        {
            guard lists.count > 1,
                let sublistRoot = self[focusedListIndex - 1]?.root,
                let firstRoot = sublistRoot.root else { return }
            
            newList.set(root: firstRoot)
            newList.selection.set(with: sublistRoot)
        }
        else
        {
            updateRootOfList(at: lists.count - 1)
            
            focusedList.select()
        }
    }
    
    func canMove(_ direction: Direction) -> Bool
    {
        let indexOffset = direction == .left ? -1 : 1
        
        return lists[focusedListIndex + indexOffset].root != nil
    }
    
    // MARK: - Create Task Lists
    
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
        
        if index < lists.count - 1 { updateRootOfList(at: index + 1) }
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
    
    subscript(_ index: Int) -> SelectableList?
    {
        guard lists.isValid(index: index) else { return nil }
        
        return lists[index]
    }
    
    var numberOfLists: Int { return lists.count }
    
    var focusedList: SelectableList { return lists[focusedListIndex] }
    private let focusedListIndex = 2
    private var lists = [SelectableList]()
    
    // MARK: - Observability
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event { case didNothing, didMove(direction: Direction) }
}
