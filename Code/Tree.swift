import SwiftyToolz

extension Tree
{
    // MARK: - Editing
    
    @discardableResult
    func mergeBranches(at indexes: [Int],
                       as merged: Self,
                       at index: Int) -> [Self]?
    {
        guard
            branches.isValid(index: index),
            branches.isValid(index: indexes.min()),
            branches.isValid(index: indexes.max())
        else
        {
            log(warning: "Tried to group tasks at invalid indexes \(indexes).")
            return nil
        }
        
        guard let removedBranches = removeBranches(at: indexes) else { return nil }
        
        guard insert(branch: merged, at: index) else { return nil }
        
        for removed in removedBranches
        {
            merged.insert(branch: removed, at: merged.numberOfBranches)
        }
        
        return removedBranches
    }
    
    @discardableResult
    func removeBranches(at indexes: [Int]) -> [Self]?
    {
        var sortedIndexes = indexes.sorted()
        
        guard branches.isValid(index: sortedIndexes.first),
              branches.isValid(index: sortedIndexes.last)
        else
        {
            log(warning: "Tried to remove branches at invalid indexes \(indexes).")
            return nil
        }
        
        var removedBranches = [Self]()
        
        while let indexToRemove = sortedIndexes.popLast()
        {
            let removedBranch = branches.remove(at: indexToRemove)
            
            removedBranch.root = nil
            
            removedBranches.insert(removedBranch, at: 0)
        }
        
        return removedBranches
    }
    
    @discardableResult
    func insert(branch: Self, at index: Int) -> Bool
    {
        guard index >= 0, index <= branches.count else
        {
            log(warning: "Tried to insert branch at out of bound index \(index).")
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
    
    // MARK: - Branches
    
    func recoverRoots()
    {
        for branch in branches
        {
            branch.root = self
            branch.recoverRoots()
        }
    }
    
    func branch(at index: Int?) -> Self?
    {
        guard let index = index else { return nil }
        
        guard branches.isValid(index: index) else
        {
            log(warning: "Tried to access subtree at out of bound index \(index).")
            return nil
        }
        
        return branches[index]
    }
    
    func index(of branch: Self) -> Int?
    {
        return branches.index { $0 === branch }
    }
    
    var indexInRoot: Int? { return root?.index(of: self) }
    var hasBranches: Bool { return branches.count > 0 }
    var numberOfBranches: Int { return branches.count }
}

protocol Tree: class
{
    var root: Self? { get set }
    var branches: [Self] { get set }
}
