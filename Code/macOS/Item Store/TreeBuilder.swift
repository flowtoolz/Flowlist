import SwiftyToolz

class TreeBuilder
{
    func buildTree(from updates: [ItemUpdate]) -> Item?
    {
        let treeResult = updates.makeTrees()
        
        guard treeResult.trees.count > 1 else
        {
            return treeResult.trees.first
        }
        
        log(warning: "There are multiple trees in iCloud.")
        
        if let storeRootID = ItemStore.shared.root?.id,
            let matchingRoot = treeResult.trees.first(where: { $0.id == storeRootID })
        {
            log("... We found a tree in iCloud whos root ID matches the local tree's root ID, so we're gonna use that tree.")
            return matchingRoot
        }
        
        log("... We found no matching root ID in iCloud, so we're gonna use the largest tree from iCloud.")
        return treeResult.largestTree
    }
}

private extension Array where Element == ItemUpdate
{
    func makeTrees() -> TreeBuildingResult
    {
        guard !isEmpty else
        {
            return TreeBuildingResult(trees: [], detachedUpdates: [])
        }
        
        // create unconnected items. remember corresponding updates.
        
        let hashMap = reduce(into: [ItemData.ID : (ItemUpdate, Item)]())
        {
            hash, update in
            
            hash[update.data.id] = (update, Item(data: update.data))
        }
        
        // connect items. remember roots and unconnected records.
        
        var trees = [Item]()
        var detachedUpdates = [ItemUpdate]()
        
        hashMap.forEach
        {
            let (update, item) = $1
            
            guard let rootID = update.parentID else
            {
                trees.append(item)
                return
            }
            
            guard let (_, rootItem) = hashMap[rootID] else
            {
                detachedUpdates.append(update)
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
                let leftPos = hashMap[$0.id]?.0.position ?? 0
                let rightPos = hashMap[$1.id]?.0.position ?? 0
                
                return leftPos < rightPos
            }
        }
        
        return TreeBuildingResult(trees: trees,
                                  detachedUpdates: detachedUpdates)
    }
}

struct TreeBuildingResult
{
    var largestTree: Item?
    {
        if trees.count == 1 { return trees[0] }
        trees.forEach { _ = $0.calculateNumberOfLeafs() }
        return (trees.sorted { $0.numberOfLeafs > $1.numberOfLeafs }).first
    }
    
    let trees: [Item]
    let detachedUpdates: [ItemUpdate]
}

struct ItemUpdate
{
    let data: ItemData
    let parentID: ItemData.ID?
    let position: Int
}
