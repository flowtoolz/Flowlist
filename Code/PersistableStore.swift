import SwiftObserver

typealias PersistableStore = Persistable & StoreInterface

protocol StoreInterface: Observable where UpdateType == StoreEvent
{
    func apply(_ itemEdit: Item.Interaction)
    func update(root newRoot: Item)
}
