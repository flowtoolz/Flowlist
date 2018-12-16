import PromiseKit
import SwiftyToolz

extension Store
{
    func saveItems(to file: ItemFile?)
    {
        guard let file = file else
        {
            log(error: "File is nil.")
            return
        }
        
        guard let root = root else
        {
            log(error: "Store has no root item.")
            return
        }
        
        file.save(root)
    }
    
    func loadItems(from file: ItemFile?) -> Promise<Void>
    {
        guard let file = file else
        {
            return Promise(error: StoreError.message("File is nil."))
        }
        
        guard let item = file.loadItem() else
        {
            let error = StoreError.message("Couldn't load items from file.")
            return Promise(error: error)
        }
        
        return update(root: item)
    }
}
