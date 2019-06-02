import CloudKit

// TODO: this hasn't been used at least since 1.7.0., possibly never. what's goin on?

extension ChangeFetchResult
{
    func makeEdits() -> [Edit]
    {
        var edits = [Edit]()
        
        if idsOfDeletedCKRecords.count > 0
        {
            let ids = idsOfDeletedCKRecords.map
            {
                $0.recordName
            }
            
            edits.append(.removeItems(withIDs: ids))
        }
        
        if changedCKRecords.count > 0
        {
            let records = changedCKRecords.map(Record.init)
            
            edits.append(.updateItems(withRecords: records))
        }
        
        return edits
    }
}
