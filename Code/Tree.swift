import SwiftObserver
import SwiftyToolz

// MARK: - Tree

final class Tree<Data: Copyable>: Copyable, Observable
{
    // MARK: - Copyable
    
    convenience init(with original: Node)
    {
        self.init(with: original, root: nil)
    }
    
    convenience init(with original: Node, root: Node? = nil)
    {
        self.init(data: original.data?.copy,
                  root: root,
                  numberOfLeafs: original.numberOfLeafs)
        
        for subtask in original.branches
        {
            let subCopy = Node(with: subtask, root: self)
            
            branches.append(subCopy)
        }
    }
    
    // MARK: - Initialization
    
    init(data: Data?, root: Node? = nil, numberOfLeafs: Int = 1)
    {
        self.data = data
        self.root = root
        self.numberOfLeafs = numberOfLeafs
    }
    
    // MARK: - Group
    
    @discardableResult
    func groupNodes(at indexes: [Int]) -> Node?
    {
        let sortedIndexes = indexes.sorted()
        
        guard let groupIndex = sortedIndexes.first,
            branches.isValid(index: groupIndex),
            branches.isValid(index: sortedIndexes.last)
        else
        {
            log(error: "Tried to merge branches at invalid indexes \(indexes).")
            return nil
        }
        
        guard let mergedNodes = removeNodes(from: indexes) else { return nil }
        
        let group = Node(data: nil)
        
        guard insert(group, at: groupIndex) else { return nil }
        
        for removedNode in mergedNodes
        {
            group.add(removedNode)
        }
        
        return group
    }

    // MARK: - Remove
    
    @discardableResult
    func removeNodes(from indexes: [Int]) -> [Node]?
    {
        var sortedIndexes = indexes.sorted()
        
        guard branches.isValid(index: sortedIndexes.first),
            branches.isValid(index: sortedIndexes.last)
        else
        {
            log(error: "Tried to remove nodes from invalid indexes \(indexes).")
            return nil
        }
        
        var removedNodes = [Node]()
        
        while let indexToRemove = sortedIndexes.popLast()
        {
            let removedNode = branches.remove(at: indexToRemove)
            
            removedNode.root = nil
            
            removedNodes.insert(removedNode, at: 0)
        }
        
        lastRemoved.storeCopies(of: removedNodes)
        
        updateNumberOfLeafs()
        
        send(.did(.remove(removedNodes, from: indexes)))
        
        return removedNodes
    }
    
    // MARK: - Insert
    
    @discardableResult
    func add(_ node: Node) -> Bool
    {
        return insert(node, at: count)
    }
    
    @discardableResult
    func insert(_ node: Node, at index: Int) -> Bool
    {
        return insert([node], at: index)
    }
    
    @discardableResult
    func insert(_ nodes: [Node], at index: Int) -> Bool
    {
        guard nodes.count > 0 else { return false }
        
        guard index >= 0, index <= count else
        {
            log(error: "Tried to insert nodes at invalid index \(index).")
            return false
        }
        
        branches.insert(contentsOf: nodes, at: index)
        
        for node in nodes { node.root = self }
        
        updateNumberOfLeafs()
        
        send(.did(.insert(at: Array(index ..< index + nodes.count))))
        
        return true
    }
    
    // MARK: - Move
    
    @discardableResult
    func moveNode(from: Int, to: Int) -> Bool
    {
        guard branches.moveElement(from: from, to: to) else { return false }
        
        send(.did(.move(from: from, to: to)))
        
        return true
    }
    
    // MARK: - Data
    
    var data: Data?
    
    // MARK: - Undo History
    
    var numberOfRemovedBranches: Int { return lastRemoved.count }
    
    let lastRemoved = Clipboard<Node>()
    
    // MARK: - Counting Leafs
    
    @discardableResult
    func recoverNumberOfLeafs() -> Int
    {
        if isLeaf
        {
            numberOfLeafs = 1
            return numberOfLeafs
        }
        
        var subtaskLeafs = 0
        
        for subtask in branches
        {
            subtaskLeafs += subtask.recoverNumberOfLeafs()
        }
        
        numberOfLeafs = subtaskLeafs
        
        return numberOfLeafs
    }
    
    func updateNumberOfLeafs()
    {
        let newNumber = numberOfLeafsRecursively()
        
        guard newNumber != numberOfLeafs else { return }
        
        numberOfLeafs = newNumber
        root?.updateNumberOfLeafs()
        
        send(.didChange(numberOfLeafs: numberOfLeafs))
    }
    
    func numberOfLeafsRecursively() -> Int
    {
        if isLeaf { return 1 }
        
        var subtaskLeafs = 0
        
        for subtask in branches
        {
            subtaskLeafs += subtask.numberOfLeafs
        }
        
        return subtaskLeafs
    }
    
    private(set) var numberOfLeafs = 1
    
    // MARK: - Root
    
    var indexInRoot: Int? { return root?.index(of: self) }
    
    weak var root: Node?
    {
        didSet
        {
            guard oldValue !== root else { return }

            send(.did(.changeRoot(from: oldValue, to: root)))
        }
    }
    
    // MARK: - Observability
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event { case didNothing, did(Edit), didChange(numberOfLeafs: Int) }
    
    enum Edit
    {
        case nothing
        case changeRoot(from: Node?, to: Node?)
        case insert(at: [Int])
        case move(from: Int, to: Int)
        case remove([Node], from: [Int])
        
        var modifiesContent: Bool
        {
            switch self
            {
            case .remove, .insert, .changeRoot: return true
            default: return false
            }
        }
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
    
    func reset(branches newBranches: [Node])
    {
        branches = newBranches
    }
    
    subscript(_ indexes: [Int]) -> [Node]
    {
        let result = branches[indexes]
        
        if result.count != indexes.count
        {
            log(warning: "Tried to access at least 1 branch at invalid index.")
        }
        
        return result
    }
    
    subscript(_ index: Int?) -> Node?
    {
        guard branches.isValid(index: index), let validIndex = index else
        {
            log(warning: "Tried to access branch at invalid index \(String(describing: index)).")
            return nil
        }
        
        return branches[validIndex]
    }
    
    func index(of branch: Node) -> Int?
    {
        return branches.index { $0 === branch }
    }
    
    var isLeaf: Bool { return count == 0 }
    var count: Int { return branches.count }
    
    private(set) var branches = [Node]()
    
    // MARK: - Node
    
    typealias Node = Tree<Data>
}
