import PromiseKit
import SwiftyToolz

extension Storage
{
    func saveItems(to file: ItemFile?)
    {
        guard let file = file else
        {
            log(error: "File is nil.")
            return
        }
        
        guard let root = Store.shared.root else
        {
            log(error: "Store root is nil.")
            return
        }
        
        file.save(root)
    }
    
    func loadItems(from file: ItemFile?) -> Promise<Void>
    {
        guard let file = file else
        {
            return Promise(error: StorageError.message("File is nil."))
        }
        
        guard let item = file.loadItem() else
        {
            let error = StorageError.message("Couldn't load items from file.")
            return Promise(error: error)
        }
        
        return Store.shared.update(root: item)
    }
}
