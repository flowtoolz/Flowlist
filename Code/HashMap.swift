import SwiftObserver

class HashMap
{
    var items: [ItemDataTree] { return Array(storedItems.values) }
    
    subscript(_ id: String) -> ItemDataTree? { return storedItems[id] }
    
    func reset(with items: [ItemDataTree])
    {
        storedItems.removeAll()
        
        add(items)
    }
    
    func add(_ items: [ItemDataTree])
    {
        for item in items
        {   
            storedItems[item.data.id] = item
        }
    }
    
    func remove(_ items: [ItemDataTree])
    {
        for item in items
        {
            storedItems[item.data.id] = nil
        }
    }
    
    private var storedItems = [String : ItemDataTree]()
}
