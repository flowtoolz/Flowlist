import SwiftObserver
import SwiftyToolz

extension NewTree where Data: ListItem.Data
{
    // MARK: - Debug
    
    func debugPrint(prefix: String = "")
    {
        Swift.print(prefix + (data?.item?.title.value ?? "untitled"))
        
        for i in 0 ..< count
        {
            self[i]?.debugPrint(prefix: prefix + "\t")
        }
    }
}

class ListItem: NewTree<ListItem.Data>, Observer
{
    init(with item: Task, withBranches: Bool = true)
    {
        super.init()

        set(data: Data(with: item))
        
        if withBranches
        {
            for subItem in item.branches
            {
                append(ListItem(with: subItem))
            }
        }
    }
    
    // MARK: - Observing the Item
    
    override func set(data: ListItem.Data?)
    {
        stopObserving(self.data?.item)
        
        super.set(data: data)
        
        if let newItem = data?.item
        {
            observe(newItem)
            {
                [weak self] event in self?.didReceive(event)
            }
        }
    }
    
    private func didReceive(_ event: Task.Event)
    {
        switch event
        {
        case .didNothing: break
        case .did(let edit): did(edit)
        case .didChange(let numberOfLeafs): break
            //Swift.print("observed item did change number of leafs: \(numberOfLeafs)")
        }
    }
    
    private func did(_ edit: Edit)
    {
        guard let item = data?.item else { return }
        
        switch edit
        {
        case .nothing:
            break
            
        case .changeRoot(let from, let to):
            Swift.print("observed item did change root from \(String(describing: from?.title)) to \(to?.title)")
            
        case .create(let at):
            guard let newSubItem = item[at] else
            {
                log(error: "Couldn't find newly created item.")
                return
            }
            
            insert(ListItem(with: newSubItem, withBranches: false), at: at)
            
        case .insert(let at):
            guard at.count > 0 else { return }
            
            let sortedInsertionIndexes = at.sorted()
            
            for insertionIndex in sortedInsertionIndexes
            {
                guard let insertedItem = item[insertionIndex] else
                {
                    log(error: "Couldn't find list item for inserted item at index \(insertionIndex)")
                    return
                }
                
                insert(ListItem(with: insertedItem), at: insertionIndex)
            }
            
        case .move(let from, let to):
            moveNode(from: from, to: to)
            
        case .remove(_, let from):
            removeNodes(from: from)
        }
    }
    
    // MARK: - List Item Data
    
    class Data
    {
        init(with item: Task)
        {
            self.item = item
        }
        
        private(set) weak var item: Task?
    }
}
