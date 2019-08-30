import SwiftyToolz

extension Tree where Data == ItemData
{
    func cut(at indexes: [Int]) -> Bool
    {
        let nodes = self[indexes]
        
        guard !nodes.isEmpty else { return false }
        
        clipboard.storeCopiesAndOriginals(of: nodes)
        
        return removeChildren(from: indexes) != nil
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
        
        clipboard.storeCopies(of: nodes)
        
        return true
    }
}

let clipboard = Clipboard<Item>()
