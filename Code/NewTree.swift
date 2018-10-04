import SwiftObserver
import SwiftyToolz

// MARK: - Edit Branches

extension NewTree
{
    @discardableResult
    func mergeBranches(at indexes: [Int], as mergedBranch: Node) -> [Node]?
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
        
        guard let removedBranches = removeBranches(from: indexes) else
        {
            return nil
        }
        
        insert(mergedBranch, at: firstIndex)
        
        for removedBranch in removedBranches
        {
            mergedBranch.append(removedBranch)
        }
        
        return removedBranches
    }
    
    @discardableResult
    func removeBranches(from indexes: [Int]) -> [Node]?
    {
        var sortedIndexes = indexes.sorted()
        
        guard branches.isValid(index: sortedIndexes.first),
            branches.isValid(index: sortedIndexes.last)
            else
        {
            log(error: "Tried to remove branches from invalid indexes \(indexes).")
            return nil
        }
        
        var removedBranches = [Node]()
        
        while let indexToRemove = sortedIndexes.popLast()
        {
            let removedBranch = branches.remove(at: indexToRemove)
            
            removedBranch.root = nil
            
            removedBranches.insert(removedBranch, at: 0)
        }
        
        return removedBranches
    }
    
    @discardableResult
    func insert(_ toInsert: [Node], at index: Int) -> Bool
    {
        guard index >= 0, index <= count else
        {
            log(error: "Tried to insert branches at invalid index \(index).")
            return false
        }
        
        branches.insert(contentsOf: toInsert, at: index)
        
        for inserted in toInsert { inserted.root = self }
        
        return true
    }
    
    @discardableResult
    func append(_ branch: Node) -> Bool
    {
        return insert(branch, at: count)
    }
    
    @discardableResult
    func insert(_ branch: Node, at index: Int) -> Bool
    {
        guard index >= 0, index <= branches.count else
        {
            log(error: "Tried to insert branch at invalid index \(index).")
            return false
        }
        
        branches.insert(branch, at: index)
        
        branch.root = self
        
        return true
    }
    
    @discardableResult
    func moveBranch(from: Int, to: Int) -> Bool
    {
        return branches.moveElement(from: from, to: to)
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

// MARK: - Observing Trees

extension NewTree: Observable
{
    var latestUpdate: Event { return Event.didNothing }
    
    enum Event { case didNothing, did(edit: Edit) }
    
    enum Edit { case move, remove, insert, changeRoot }
}

// MARK: - Tree

class NewTree<Data>
{
    var data: Data?
    
    fileprivate var branches = [Node]()
    private(set) weak var root: Node?
    
    typealias Node = NewTree<Data>
}
