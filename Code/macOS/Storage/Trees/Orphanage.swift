class Orphanage
{
    // MARK: - Read
    
    func orphans(forParent parent: ItemData.ID) -> [Update]?
    {
        guard let hashMap = orphansByParent[parent] else { return nil }
        return Array(hashMap.values)
    }
    
    // MARK: - Update
    
    func update(_ orphan: Update, withParent parent: ItemData.ID)
    {
        if orphansByParent[parent] == nil
        {
            orphansByParent[parent] = [orphan.data.id : orphan]
        }
        else
        {
            orphansByParent[parent]?[orphan.data.id] = orphan
        }
    }
    
    // MARK: - Remove
    
    func removeOrphan(with id: ItemData.ID, parent: ItemData.ID)
    {
        orphansByParent[parent]?[id] = nil
    }
    
    func removeOrphans(forParent parent: ItemData.ID)
    {
        orphansByParent[parent] = nil
    }
    
    @discardableResult
    func removeOrphan(with id: ItemData.ID) -> Bool
    {
        for parent in orphansByParent.keys
        {
            if orphansByParent[parent]?[id] != nil
            {
                orphansByParent[parent]?[id] = nil
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Storage
    
    private var orphansByParent = [ItemData.ID : [ItemData.ID : Update]]()
}
