import SwiftObserver

typealias PersistableStore = Persistable & StoreInterface

protocol StoreInterface: Observable where UpdateType == StoreEvent
{
    func apply(_ itemEdit: ItemDataTree.Interaction)
    func update(root newRoot: ItemDataTree)
}
