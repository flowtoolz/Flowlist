import SwiftObserver

extension Store
{
    func resetWithItems(fromAvailableDatabase database: Database,
                        handleSuccess: @escaping (Bool) -> Void)
    {
        guard database.isAvailable == true else
        {
            log(error: "Database is unavailable.")
            handleSuccess(false)
            return
        }
        
        database.fetchItemTree()
        {
            if let root = $0
            {
                self.update(root: root)
                handleSuccess(true)
            }
            else
            {
                log(error: "Couldn't fetch item tree. Falling back to file.")
                handleSuccess(false)
            }
        }
    }
    
    func resetDatabaseItems(inAvailableDatabase database: Database)
    {
        guard database.isAvailable == true else
        {
            log(error: "Database is unavailable.")
            return
        }
        
        guard let root = root else
        {
            log(error: "No root in store")
            return
        }
        
        database.resetItemTree(with: root)
    }
}
