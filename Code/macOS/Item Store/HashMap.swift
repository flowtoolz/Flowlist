import SwiftObserver

class HashMap
{
    var items: [Item] { return Array(storedItems.values) }
    
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
    
    subscript(_ id: ItemData.ID) -> Item?
    {
        get { return storedItems[id] }
        
        set { storedItems[id] = newValue }
    }
    
    private var storedItems = [ItemData.ID : Item]()
}
