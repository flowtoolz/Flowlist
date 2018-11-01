import SwiftyToolz

extension Tree where Data == ItemData
{
    func cut(at indexes: [Int]) -> Bool
    {
        guard copy(at: indexes) else { return false }
        
        removeNodes(from: indexes)
        
        return true
    }
    
    @discardableResult
    func copy(at indexes: [Int]) -> Bool
    {
        let nodes = self[indexes]
        
        return copy(nodes)
    }
    
    @discardableResult
    func copy(_ items: [ItemDataTree]) -> Bool
    {
        guard !items.isEmpty else { return false }
        
        clipboard.storeCopies(of: items)
        
        return true
    }
    
    var clipboardItems: [ItemDataTree]
    {
        return clipboard.copiesOfStoredObjects
    }
}

let clipboard = Clipboard<ItemDataTree>()
