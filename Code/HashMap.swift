import SwiftObserver

class HashMap
{
    var items: [Item] { return Array(storedItems.values) }
    
    subscript(_ id: String) -> Item? { return storedItems[id] }
    
    func reset(with items: [Item])
    {
        storedItems.removeAll()
        
        add(items)
    }
    
    func add(_ items: [Item])
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
    
    func remove(_ items: [Item])
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
    
    private var storedItems = [String : Item]()
}
