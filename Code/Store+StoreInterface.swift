import SwiftObserver

extension Store: StoreInterface
{
    func apply(_ itemEdit: Item.Operation)
    {
        switch itemEdit
        {
        case .didNothing: break
        case .didCreate(let edit): createItem(with: edit)
        case .didModify(let edit): updateItem(with: edit)
        case .didDelete(let id): removeItem(with: id)
        }
    }
    
    private func createItem(with edit: Item.Edit)
    {
        let newItem = Item(with: edit)
        
        itemHash.add([newItem])
        
        guard let rootId = edit.rootId else
        {
            log(warning: "New item (id \(edit.id)) has no root.")
            return
        }
        
        guard let rootItem = itemHash[rootId] else
        {
            log(warning: "Root (id \(rootId)) of new item (id \(edit.id)) is not in hash map.")
            return
        }
        
        rootItem.add(newItem)
    }
    
    private func updateItem(with edit: Item.Edit)
    {
        guard let item = itemHash[edit.id] else
        {
            log(error: "Item with id \(edit.id) is not in hash map.")
            return
        }
        
        // TODO: updating an Item with ItemEditInfo should be an Item extension
        for field in edit.modified
        {
            switch field
            {
            case .text: item.data?.text <- edit.text
            case .state: item.data?.state <- edit.state
            case .tag: item.data?.tag <- edit.tag
            case .root: log(error: "Did not expect direct modification of item root. ID: \(edit.id). Intended new root ID: \(String(describing: edit.rootId)) item Text: \(item.text ?? "nil")")
            }
        }
    }
    
    private func removeItem(with id: String)
    {
        guard let item = itemHash[id] else
        {
            log(error: "Item with id \(id) is not in hash map.")
            return
        }
        
        itemHash.remove([item])
        
        guard let superItem = item.root,
            let index = item.indexInRoot
        else
        {
            log(warning: "Did remove root with id \(id) from hash map. Text: \(item.text ?? "nil")")
            return
        }
        
        superItem.removeNodes(from: [index])
    }
}
