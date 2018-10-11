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
    func copy(_ tasks: [Item]) -> Bool
    {
        guard !tasks.isEmpty else { return false }
        
        clipboard.storeCopies(of: tasks)
        
        return true
    }
    
    var clipboardTasks: [Item]
    {
        return clipboard.copiesOfStoredObjects
    }
}

let clipboard = Clipboard<Item>()