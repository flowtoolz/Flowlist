class Orphanage
{
    // MARK: - Read
    
    func orphans(forParentID parentID: ItemData.ID) -> [Update]?
    {
        guard let hashMap = orphansByParentID[parentID] else { return nil }
        return Array(hashMap.values)
    }
    
    // MARK: - Update
    
    func update(_ orphan: Update, withParentID parentID: ItemData.ID)
    {
        if orphansByParentID[parentID] == nil
        {
            orphansByParentID[parentID] = [orphan.data.id : orphan]
        }
        else
        {
            orphansByParentID[parentID]?[orphan.data.id] = orphan
        }
    }
    
    // MARK: - Remove
    
    func removeOrphan(with id: ItemData.ID, parentID: ItemData.ID)
    {
        orphansByParentID[parentID]?[id] = nil
    }
    
    func removeOrphans(forParentID parentID: ItemData.ID)
    {
        orphansByParentID[parentID] = nil
    }
    
    @discardableResult
    func removeOrphan(with id: ItemData.ID) -> Bool
    {
        for parentID in orphansByParentID.keys
        {
            if orphansByParentID[parentID]?[id] != nil
            {
                orphansByParentID[parentID]?[id] = nil
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Storage
    
    private var orphansByParentID = [ItemData.ID : [ItemData.ID : Update]]()
}
