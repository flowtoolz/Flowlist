import SwiftObserver

typealias PersistableStore = Persistable & StoreInterface

protocol StoreInterface: Observable where UpdateType == StoreEvent
{
    func updateItem(with edit: ItemEdit)
    func update(root newRoot: Item)
}
