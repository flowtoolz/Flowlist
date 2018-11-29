import SwiftObserver
import SwiftyToolz

extension Tree
{
    var array: [Node]
    {
        var result = [self]
        
        branches.forEach { result.append(contentsOf: $0.array) }
        
        return result
    }
}

// MARK: - Tree

class Tree<Data: Copyable & Observable>: Copyable, Observable, Observer
{
    // MARK: - Copyable
    
    public required convenience init(with original: Node)
    {
        self.init(with: original, root: nil)
    }
    
    private convenience init(with original: Node, root: Node? = nil)
    {
        self.init(data: original.data.copy,
                  root: root,
                  numberOfLeafs: original.numberOfLeafs)
        
        for subitem in original.branches
        {
            let subCopy = Node(with: subitem, root: self)
            
            branches.append(subCopy)
        }
    }
    
    // MARK: - Initialization
    
    init(data: Data, root: Node? = nil, numberOfLeafs: Int = 1)
    {
        self.data = data
        self.root = root
        self.numberOfLeafs = numberOfLeafs
        
        observe(data)
        {
            [weak self] update in
            
            guard let self = self else { return }
            
            self.sendToRoot(.receivedDataUpdate(update, in: self))
        }
    }
    
    deinit
    {
        stopAllObserving()
        removeObservers()
    }
    
    // MARK: - Group
    
    @discardableResult
    func groupNodes<N>(at indexes: [Int], as group: N) -> N? where N: Node
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
        
        guard insert(group, at: groupIndex) else { return nil }
        
        mergedNodes.forEach { group.add($0) }
        
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
        
        deletionStack.append(removedNodes)
        
        updateNumberOfLeafs()
        
        send(.didUpdateNode(.removedNodes(removedNodes, from: indexes)))
        sendToRoot(.removedNodes(removedNodes, from: self))
        
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
        
        nodes.forEach { $0.root = self }
        
        updateNumberOfLeafs()
        
        let indexes = Array(index ..< index + nodes.count)
        
        send(.didUpdateNode(.insertedNodes(at: indexes)))
        sendToRoot(.insertedNodes(nodes, in: self, at: indexes))
        
        return true
    }
    
    // MARK: - Move
    
    @discardableResult
    func moveNode(from: Int, to: Int) -> Bool
    {
        guard branches.moveElement(from: from, to: to) else { return false }
        
        send(.didUpdateNode(.movedNode(from: from, to: to)))
        sendToRoot(.movedNode(branches[to], from: from, to: to))
        
        return true
    }
    
    // MARK: - Data
    
    let data: Data
    
    // MARK: - Undo Deletions
    
    var deletionStack = [[Node]]()
    
    // MARK: - Counting Leafs
    
    func updateNumberOfLeafs()
    {
        // TODO: make sure no unnecessary nodes get updated... don't traverse the whole subtree after editing operations...
        let newNumber = numberOfLeafsRecursively()
        
        guard newNumber != numberOfLeafs else { return }
        
        numberOfLeafs = newNumber
        root?.updateNumberOfLeafs()
        
        send(.didChangeLeafNumber(numberOfLeafs))
    }
    
    func numberOfLeafsRecursively() -> Int
    {
        if isLeaf { return 1 }
        
        var subitemLeafs = 0
        
        branches.forEach { subitemLeafs += $0.numberOfLeafs }
        
        return subitemLeafs
    }
    
    private(set) var numberOfLeafs = 1
    
    // MARK: - Root
    
    var indexInRoot: Int? { return root?.index(of: self) }
    
    weak var root: Node?
    {
        didSet
        {
            guard oldValue !== root else { return }

            send(.didUpdateNode(.switchedRoot(from: oldValue, to: root)))
        }
    }
    
    // MARK: - Propagate Updates to Root
    
    private func sendToRoot(_ event: Event.TreeUpdate)
    {
        guard let root = root else
        {
            send(.didUpdateTree(event))
            return
        }
        
        root.sendToRoot(event)
    }
    
    // MARK: - Observability
    
    var latestUpdate = Event.didNothing
    
    enum Event
    {
        case didNothing
        case didUpdateTree(TreeUpdate)
        case didUpdateNode(NodeUpdate)
        case didChangeLeafNumber(Int)
        
        enum TreeUpdate
        {
            case removedNodes([Node], from: Node)
            case insertedNodes([Node], in: Node, at: [Int])
            case receivedDataUpdate(Data.UpdateType, in: Node)
            case movedNode(Node, from: Int, to: Int)
        }
        
        enum NodeUpdate
        {
            case switchedRoot(from: Node?, to: Node?)
            case insertedNodes(at: [Int])
            case movedNode(from: Int, to: Int)
            case removedNodes([Node], from: [Int])
            
            var modifiesGraphStructure: Bool
            {
                switch self
                {
                case .removedNodes, .insertedNodes, .switchedRoot: return true
                default: return false
                }
            }
        }
    }
    
    // MARK: - Branches
    
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
    
    func sortWithoutSendingUpdate(comparator: (Node, Node) -> Bool)
    {
        branches.sort(by: comparator)
        
        branches.forEach
        {
            $0.sortWithoutSendingUpdate(comparator: comparator)
        }
    }
    
    func index(of branch: Node) -> Int?
    {
        return branches.index { $0 === branch }
    }
    
    var isLeaf: Bool { return count == 0 }
    var count: Int { return branches.count }
    
    private(set) var branches = [Node]()
    
    // MARK: - Node
    
    public typealias Node = Tree<Data>
}
