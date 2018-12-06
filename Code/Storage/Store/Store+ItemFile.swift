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
    
    func loadItems(from file: ItemFile?)
    {
        guard let file = file else
        {
            log(error: "File is nil.")
            return
        }
        
        guard let item = file.loadItem() else
        {
            log(error: "Couldn't load items from file.")
            return
        }
        
        update(root: item)
    }
}
