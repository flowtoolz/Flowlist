import SwiftObserver
import SwiftyToolz

// MARK: - High-Level Edits

extension NewTree
{
    @discardableResult
    func mergeNodes(at indexes: [Int], as mergedNode: Node) -> [Node]?
    {
        let sortedIndexes = indexes.sorted()
        
        guard let firstIndex = sortedIndexes.first,
            branches.isValid(index: firstIndex),
            branches.isValid(index: sortedIndexes.last)
        else
        {
            log(error: "Tried to merge branches at invalid indexes \(indexes).")
            return nil
        }
        
        guard let removedNodes = removeNodes(from: indexes) else
        {
            return nil
        }
        
        insert(mergedNode, at: firstIndex)
        
        for removedNode in removedNodes
        {
            mergedNode.append(removedNode)
        }
        
        return removedNodes
    }
    
    @discardableResult
    func append(_ node: Node) -> Bool
    {
        return insert(node, at: count)
    }
    
    @discardableResult
    func insert(_ node: Node, at index: Int) -> Bool
    {
        return insert([node], at: index)
    }
}

// MARK: - Atomic (Observable) Edits

extension NewTree
{
    @discardableResult
    func removeNodes(from indexes: [Int]) -> [Node]?
    {
        var sortedIndexes = indexes.sorted()
        
        guard branches.isValid(index: sortedIndexes.first),
            branches.isValid(index: sortedIndexes.last)
            else
        {
            log(error: "Tried to remove branches from invalid indexes \(indexes).")
            return nil
        }
        
        var removedNodes = [Node]()
        
        while let indexToRemove = sortedIndexes.popLast()
        {
            let removedNode = branches.remove(at: indexToRemove)
            
            removedNode.root = nil
            
            removedNodes.insert(removedNode, at: 0)
        }
        
        send(.did(.remove(from: indexes)))
        
        return removedNodes
    }
    
    @discardableResult
    func insert(_ toInsert: [Node], at index: Int) -> Bool
    {
        guard toInsert.count > 0 else { return false }
        
        guard index >= 0, index <= count else
        {
            log(error: "Tried to insert branches at invalid index \(index).")
            return false
        }
        
        branches.insert(contentsOf: toInsert, at: index)
        
        for insertedNode in toInsert { insertedNode.root = self }
        
        send(.did(.insert(at: Array(index ..< index + toInsert.count))))
        
        return true
    }
    
    @discardableResult
    func moveNode(from: Int, to: Int) -> Bool
    {
        let ok = branches.moveElement(from: from, to: to)
        
        if ok
        {
            send(.did(.move(from: from, to: to)))
        }
        
        return ok
    }
}

// MARK: - Access Branches

extension NewTree
{
    public var numberOfBranchesRecursively: Int
    {
        var branchNumber = 0
        
        for branch in branches
        {
            branchNumber += branch.numberOfBranchesRecursively
        }
        
        return branchNumber + 1
    }
    
    func recoverRoots()
    {
        for branch in branches
        {
            branch.root = self
            branch.recoverRoots()
        }
    }
    
    subscript(_ indexes: [Int]) -> [Node]?
    {
        let result = branches[indexes]
        
        guard result.count == indexes.count else
        {
            log(warning: "Requested branches at invalid indexes \(indexes).")
            return nil
        }
        
        return result
    }
    
    subscript(_ index: Int?) -> Node?
    {
        guard let validIndex = index, branches.isValid(index: index) else
        {
            log(warning: "Requested branch at invalid index \(String(describing: index)).")
            return nil
        }
        
        return branches[validIndex]
    }
    
    var count: Int { return branches.count }
    var indexInRoot: Int? { return root?.index(of: self) }
    var isLeaf: Bool { return branches.count == 0 }
    
    func index(of branch: Node) -> Int?
    {
        return branches.index { $0 === branch }
    }
}

// MARK: - Tree

class NewTree<Data>: Observable
{
    func set(data: Data?)
    {
        self.data = data
    }
    
    private(set) var data: Data?
    
    fileprivate var branches = [Node]()
    private(set) weak var root: Node?
    {
        didSet
        {
            guard oldValue !== root else { return }
            
            send(.did(.changeRoot(from: oldValue, to: root)))
        }
    }
    
    // MARK: - Observability
    
    var latestUpdate: Event { return Event.didNothing }
    
    enum Event { case didNothing, did(NTEdit) }
    enum NTEdit // TODO: rename to Edit when old tree has been replaced
    {
        case move(from: Int, to: Int)
        case remove(from: [Int])
        case insert(at: [Int])
        case changeRoot(from: Node?, to: Node?)
    }
    
    // MARK: - Node Type
    
    typealias Node = NewTree<Data>
}
