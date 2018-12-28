import CloudKit
import SwiftObserver
import SwiftyToolz

extension Array where Element == Record
{
    func makeTrees() -> MakeTreesResult
    {
        guard !isEmpty else
        {
            return MakeTreesResult(trees: [], detachedRecords: [])
        }
        
        // create unconnected items. remember corresponding records.
        
        let hashMap = reduce(into: [String : (Record, Item)]())
        {
            $0[$1.id] = ($1, Item(record: $1))
        }
        
        // connect items. remember roots and unconnected records.
        
        var trees = [Item]()
        var detachedRecords = [Record]()
        
        hashMap.forEach
        {
            let (record, item) = $1
            
            guard let rootID = record.rootID else
            {
                trees.append(item)
                return
            }
            
            guard let (_, rootItem) = hashMap[rootID] else
            {
                detachedRecords.append(record)
                return
            }
            
            item.root = rootItem
            
            rootItem.add(item)
        }
        
        // sort branches by position
        
        trees.forEach
        {
            $0.sortWithoutSendingUpdate
            {
                let leftPos = hashMap[$0.data.id]?.0.position ?? 0
                let rightPos = hashMap[$1.data.id]?.0.position ?? 0
                
                return leftPos < rightPos
            }
        }
        
        return MakeTreesResult(trees: trees,
                               detachedRecords: detachedRecords)
    }
}

struct MakeTreesResult
{
    let trees: [Item]
    let detachedRecords: [Record]
}
