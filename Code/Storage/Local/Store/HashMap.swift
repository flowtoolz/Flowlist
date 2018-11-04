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
            storedItems[item.data.id] = item
        }
    }
    
    func remove(_ items: [Item])
    {
        for item in items
        {
            storedItems[item.data.id] = nil
        }
    }
    
    private var storedItems = [String : Item]()
}
