import SwiftObserver
import SwiftyToolz

let browser = Browser()

class Browser: Observer, Observable
{
    // MARK: - Life Cycle
    
    fileprivate init()
    {
        3.times { pushList() }
        
        guard lists.isValid(index: focusedIndex) else { fatalError() }
        
        if TreeSelector.shared.selectedTree != nil
        {
            rootSelectorDidSelect(TreeSelector.shared.selectedTree)
        }
        
        observe(TreeSelector.shared)
        {
            [weak self] tree in DispatchQueue.main.async { self?.rootSelectorDidSelect(tree) }
        }
    }
    
    deinit { stopObserving() }
    
    // MARK: - Store Root
    
    private func rootSelectorDidSelect(_ selectedRoot: Item?)
    {
        lists[0].set(root: selectedRoot)
        move(to: 0)
        focusedList.isFocused <- true
        focusedList.select()
    }
    
    // MARK: - Navigation
    
    func move(_ direction: Direction)
    {
        guard canMove(direction) else { return }
        
        move(to: focusedIndex + (direction == .left ? -1 : 1))
    }
    
    func canMove(_ direction: Direction) -> Bool
    {
        if direction == .left { return focusedIndex > 0 }
        
        return focusedList.selectedIndexes.count == 1
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
    private func pushList() -> List
    {
        let newList = List(isRoot: lists.isEmpty)
        
        observe(list: newList)
        
        lists.append(newList)
        
        if lists.count > 1
        {
            updateRootOfList(at: lists.count - 1)
        }
        
        send(.didPush(list: newList))
        
        return newList
    }
    
    // MARK: - Observe Selections in Lists
    
    private func observe(list: List)
    {   
        observe(list).unwrap()
        {
            [weak self, weak list] event in
            
            guard let list = list else { return }
            
            if case .didChangeSelection = event
            {
                DispatchQueue.main.async { self?.listChangedSelection(list) }
            }
        }
    }
    
    private func listChangedSelection(_ list: List)
    {
        guard let index = lists.firstIndex(where: { $0 === list }) else
        {
            log(error: "Received update from unmanaged list.")
            return
        }
    
        for i in index + 1 ..< lists.count
        {
            updateRootOfList(at: i)
            
            if self[i + 1]?.root == nil { break }
        }
        
        send(.selectionChanged(in: list))
    }
    
    // MARK: - Lists
    
    private func updateRootOfList(at index: Int)
    {
        guard index > 0, index < lists.count else
        {
            log(warning: "Tried to update root of list at invaid index \(index).")
            return
        }
        
        let superList = lists[index - 1]
        
        let superSelection = superList.selectedIndexes
        
        let newRoot: Item? =
        {
            guard superSelection.count == 1 else { return nil }
            
            return superList[superSelection[0]]
        }()
        
        let list = lists[index]
        
        if newRoot !== list.root { list.set(root: newRoot) }
    }
    
    subscript(_ index: Int) -> List? { lists.at(index) }
    
    var focusedList: List { lists[focusedIndex] }
    var focusedIndex: Int { focusedIndexVariable.value }
    let focusedIndexVariable = Var(0)
    
    var numberOfLists: Int { lists.count }
    private(set) var lists = [List]()
    
    // MARK: - Observability
    
    let messenger = Messenger<Event?>()
    
    enum Event
    {
        case didPush(list: List)
        case selectionChanged(in: List)
    }
}
