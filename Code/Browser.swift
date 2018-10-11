import SwiftObserver
import SwiftyToolz

let browser = Browser()

class Browser: Observer, Observable
{
    // MARK: - Life Cycle
    
    fileprivate init()
    {
        pushList()
        pushList()
        pushList()
        
        guard lists.isValid(index: focusedIndex) else
        {
            fatalError()
        }
        
        focusedList.set(root: store.root)
        focusedList.select()
        focusedList.isFocused <- true
    }
    
    deinit { stopAllObserving() }
    
    // MARK: - Navigation
    
    func move(_ direction: Direction)
    {
        guard canMove(direction) else { return }
        
        move(to: focusedIndex + (direction == .left ? -1 : 1))
    }
    
    func canMove(_ direction: Direction) -> Bool
    {
        if direction == .left { return focusedIndex > 0 }
        
        return focusedList.selection.count == 1
    }
    
    func move(to index: Int)
    {
        guard index != focusedIndexVariable.value, lists.isValid(index: index) else
        {
            return
        }
        
        while index >= numberOfLists - 2 { pushList() }
        
        focusedList.isFocused <- false
        
        focusedIndexVariable <- index
        
        focusedList.isFocused <- true
        focusedList.select()
    }
    
    // MARK: - Create Lists
    
    @discardableResult
    private func pushList() -> SelectableList
    {
        let newList = SelectableList()
        
        observeSelection(in: newList)
        
        lists.append(newList)
        
        updateRootOfList(at: lists.count - 1)
        
        send(.didPush(list: newList))
        
        return newList
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
        
        observe(list.selection)
        {
            [weak self, weak list] event in
            
            guard let list = list else { return }
            
            if case .didChange(let indexes) = event
            {
                self?.listChangedSelection(list, at: indexes)
            }
        }
    }
    
    private func listChangedSelection(_ list: SelectableList,
                                      at indexes: [Int])
    {
        guard let index = lists.index(where: { $0 === list }) else
        {
            log(error: "Received update from unmanaged list.")
            return
        }
        
        if !indexes.isEmpty
        {
            send(.listDidChangeSelection(listIndex: index,
                                         selectionIndexes: indexes))
        }
    
        for i in index + 1 ..< lists.count
        {
            updateRootOfList(at: i)
            
            if self[i + 1]?.root == nil { break }
        }
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
        let newRoot = superSelection.count == 1 ? superSelection.someTask : nil
        let list = lists[index]
        
        if newRoot !== list.root { list.set(root: newRoot) }
    }
    
    subscript(_ index: Int) -> SelectableList?
    {
        guard lists.isValid(index: index) else { return nil }
        
        return lists[index]
    }
    
    var focusedList: SelectableList { return lists[focusedIndex] }
    var focusedIndex: Int { return focusedIndexVariable.value ?? 0 }
    let focusedIndexVariable = Var(0)
    
    var numberOfLists: Int { return lists.count }
    private var lists = [SelectableList]()
    
    // MARK: - Observability
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event
    {
        case didNothing
        case didPush(list: SelectableList)
        case listDidChangeSelection(listIndex: Int, selectionIndexes: [Int])
    }
}
