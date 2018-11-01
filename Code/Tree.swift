import SwiftObserver
import SwiftyToolz

// MARK: - Tree

class Tree<Data: Copyable>: Copyable
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
        
        deletionStack.append(removedNodes)
        
        updateNumberOfLeafs()
        
        messenger.send(.didEditNode(.remove(removedNodes, from: indexes)))
        sendToRoot(.remove(removedNodes, from: self))
        
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
        
        let indexes = Array(index ..< index + nodes.count)
        
        messenger.send(.didEditNode(.insert(at: indexes)))
        sendToRoot(.insert(nodes, in: self, at: indexes))
        
        return true
    }
    
    // MARK: - Move
    
    @discardableResult
    func moveNode(from: Int, to: Int) -> Bool
    {
        guard branches.moveElement(from: from, to: to) else { return false }
        
        messenger.send(.didEditNode(.move(from: from, to: to)))
        
        return true
    }
    
    // MARK: - Data
    
    let data: Data
    
    // MARK: - Undo Deletions
    
    var deletionStack = [[Node]]()
    
    // MARK: - Counting Leafs
    
    @discardableResult
    func recoverNumberOfLeafs() -> Int
    {
        if isLeaf
        {
            numberOfLeafs = 1
            return numberOfLeafs
        }
        
        var subitemLeafs = 0
        
        for subitem in branches
        {
            subitemLeafs += subitem.recoverNumberOfLeafs()
        }
        
        numberOfLeafs = subitemLeafs
        
        return numberOfLeafs
    }
    
    func updateNumberOfLeafs()
    {
        let newNumber = numberOfLeafsRecursively()
        
        guard newNumber != numberOfLeafs else { return }
        
        numberOfLeafs = newNumber
        root?.updateNumberOfLeafs()
        
        messenger.send(.didChangeLeafNumber(numberOfLeafs))
    }
    
    func numberOfLeafsRecursively() -> Int
    {
        if isLeaf { return 1 }
        
        var subitemLeafs = 0
        
        for subitem in branches
        {
            subitemLeafs += subitem.numberOfLeafs
        }
        
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

            messenger.send(.didEditNode(.switchRoot(from: oldValue,
                                                    to: root)))
        }
    }
    
    // MARK: - Propagate Updates to Root
    
    private func sendToRoot(_ event: Messenger.Event.TreeEdit)
    {
        guard let root = root else
        {
            messenger.send(.didEditTree(event))
            return
        }
        
        root.sendToRoot(event)
    }
    
    // MARK: - Observability
    
    private var messenger: Messenger { return treeMessenger }
    let treeMessenger = Messenger()
    
    class Messenger: Observable
    {
        deinit { removeObservers() }
        
        var latestUpdate = Event.didNothing
        
        enum Event
        {
            case didNothing
            case didEditTree(TreeEdit)
            case didEditNode(NodeEdit)
            case didChangeLeafNumber(Int)
            
            enum TreeEdit
            {
                case remove(_ nodes: [Node], from: Node)
                case insert(_ nodes: [Node], in: Node, at: [Int])
            }
            
            enum NodeEdit
            {
                case nothing
                case switchRoot(from: Node?, to: Node?)
                case insert(at: [Int])
                case move(from: Int, to: Int)
                case remove([Node], from: [Int])
                
                var modifiesGraphStructure: Bool
                {
                    switch self
                    {
                    case .remove, .insert, .switchRoot: return true
                    default: return false
                    }
                }
            }
        }
    }
    
    // MARK: - Branches
    
    var array: [Node]
    {
        var result = [Node]()
        
        result.append(self)
        
        for branch in branches
        {
            result.append(contentsOf: branch.array)
        }
        
        return result
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
    
    public typealias Node = Tree<Data>
}
