import SwiftObserver

extension Record
{
    init(item: Item)
    {
        let data = item.data
        
        self.init(id: data.id,
                  text: data.text.value,
                  state: data.state.value,
                  tag: data.tag.value,
                  rootID: item.root?.data.id,
                  position: item.indexInRoot ?? 0)
    }
    
    func makeItem() -> Item
    {
        let data = ItemData(id: id)
        
        data.text <- text
        data.state <- state
        data.tag <- tag
        
        return Item(data: data)
    }
    
    static func makeRecordsRecursively(for item: Item?, at position: Int? = nil) -> [Record]
    {
        guard let item = item else { return [] }
        
        // calling indexInRoot just once in the first call, so performance is ok
        let recPosition = position ?? (item.indexInRoot ?? 0)
        
        let data = item.data
        
        let record = Record(id: data.id,
                            text: data.text.value,
                            state: data.state.value,
                            tag: data.tag.value,
                            rootID: item.root?.data.id,
                            position: recPosition)
        
        var result = [record]
        
        for subPosition in 0 ..< item.count
        {
            guard let subItem = item[subPosition] else { continue }
            
            result += makeRecordsRecursively(for: subItem, at: subPosition)
        }
        
        return result
    }
}

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
            $0[$1.id] = ($1, $1.makeItem())
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
    var largestTree: Item?
    {
        if trees.count == 1 { return trees[0] }
        trees.forEach { _ = $0.calculateNumberOfLeafs() }
        return (trees.sorted { $0.numberOfLeafs > $1.numberOfLeafs }).first
    }
    
    let trees: [Item]
    let detachedRecords: [Record]
}
