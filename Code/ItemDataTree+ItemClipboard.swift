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
    func copy(_ nodes: [Node]) -> Bool
    {
        guard !nodes.isEmpty else { return false }
        
        let items = nodes.map { Item(from: $0) }
        clipboard.storeCopies(of: items)
        
        return true
    }
    
    var clipboardItems: [Item]
    {
        return clipboard.copiesOfStoredObjects
    }
}

let clipboard = Clipboard<Item>()
