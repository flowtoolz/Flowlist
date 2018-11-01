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
            guard let data = item.data else
            {
                log(error: "Item has no data.")
                return
            }
            
            storedItems[data.id] = item
        }
    }
    
    func remove(_ items: [ItemDataTree])
    {
        for item in items
        {
            guard let data = item.data else
            {
                log(error: "Item has no data.")
                return
            }
            
            storedItems[data.id] = nil
        }
    }
    
    private var storedItems = [String : ItemDataTree]()
}
