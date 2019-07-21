import SwiftObserver

class HashMap
{
    var count: Int { return storedItems.count }
    func contains(_ item: Item) -> Bool { return storedItems[item.id] != nil }
    func add(_ items: [Item]) { items.forEach { add($0) } }
    func add(_ item: Item) { storedItems[item.id] = item }
    func remove(_ items: [Item]) { items.forEach { remove($0) } }
    func remove(_ item: Item) { storedItems[item.id] = nil }
    subscript(_ id: ItemData.ID) -> Item? { return storedItems[id] }
    
    private var storedItems = [ItemData.ID : Item]()
}
