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
        items.forEach { storedItems[$0.id] = $0 }
    }
    
    func remove(_ items: [Item])
    {
        items.forEach { storedItems[$0.id] = nil }
    }
    
    private var storedItems = [String : Item]()
}
