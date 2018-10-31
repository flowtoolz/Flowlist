import SwiftObserver

typealias PersistableStore = Persistable & StoreInterface

protocol StoreInterface: Observable where UpdateType == StoreEvent
{
    func apply(_ itemEdit: Item.Edit)
    func update(root newRoot: Item)
}
