import SwiftObserver
import SwiftyToolz

extension Tree
{
    var allNodesRecursively: [Node]
    {
        var result = [self]
        
        children.forEach { result.append(contentsOf: $0.allNodesRecursively) }
        
        return result
    }
}

// MARK: - Tree

class Tree<Data: Copyable & Observable>: Copyable, Observer
{
    // MARK: - Copyable
    
    public required convenience init(with original: Node)
    {
        self.init(with: original, parent: nil)
    }
    
    private convenience init(with original: Node, parent: Node? = nil)
    {
        self.init(data: original.data.copy,
                  parent: parent,
                  numberOfLeafs: original.numberOfLeafs)
        
        for subitem in original.children
        {
            let subCopy = Node(with: subitem, parent: self)
            
            children.append(subCopy)
        }
    }
    
    // MARK: - Life Cycle
    
    init(data: Data, parent: Node? = nil, numberOfLeafs: Int = 1)
    {
        self.data = data
        self.parent = parent
        self.numberOfLeafs = numberOfLeafs
        
        observe(data)
        {
            [weak self] update in
            
            guard let self = self else { return }
            
            self.sendToRoot(.receivedMessage(update, fromDataIn: self))
        }
    }
    
    deinit { stopObserving(data) }
    
    // MARK: - Group
    
    @discardableResult
    func groupChildren<N>(at indexes: [Int], as group: N) -> N? where N: Node
    {
        let sortedIndexes = indexes.sorted()
        
        guard let groupIndex = sortedIndexes.first,
            children.isValid(index: groupIndex),
            children.isValid(index: sortedIndexes.last)
        else
        {
            log(error: "Tried to merge branches at invalid indexes \(indexes).")
            return nil
        }
        
        guard let mergedNodes = removeChildren(from: indexes) else { return nil }
        
        guard insert(group, at: groupIndex) else { return nil }
        
        mergedNodes.forEach { group.add($0) }
        
        return group
    }

    // MARK: - Remove
    
    @discardableResult
    func removeChildren(from indexes: [Int]) -> [Node]?
    {
        var sortedIndexes = indexes.sorted()
        
        guard children.isValid(index: sortedIndexes.first),
            children.isValid(index: sortedIndexes.last)
        else
        {
            log(error: "Tried to remove nodes from invalid indexes \(indexes).")
            return nil
        }
        
        var removedNodes = [Node]()
        
        while let indexToRemove = sortedIndexes.popLast()
        {
            let removedNode = children.remove(at: indexToRemove)
            
            removedNode.parent = nil
            
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
    func add(_ child: Node) -> Bool
    {
        insert(child, at: count)
    }
    
    @discardableResult
    func insert(_ child: Node, at index: Int) -> Bool
    {
        insert([child], at: index)
    }
    
    @discardableResult
    func insert(_ childrenToInsert: [Node], at index: Int) -> Bool
    {
        guard childrenToInsert.count > 0 else { return false }
        
        let insertionIndex = Swift.min(index, count)
        
        guard insertionIndex >= 0 else
        {
            log(error: "Tried to insert nodes at invalid index \(index).")
            return false
        }
        
        children.insert(contentsOf: childrenToInsert, at: insertionIndex)
        
        childrenToInsert.forEach { $0.parent = self }
        
        updateNumberOfLeafs()
        
        let lastPosition = insertionIndex + childrenToInsert.count - 1
        
        send(.didUpdateNode(.insertedNodes(first: insertionIndex, last: lastPosition)))
        sendToRoot(.insertedNodes(childrenToInsert, in: self, first: insertionIndex, last: lastPosition))
        
        return true
    }
    
    // MARK: - Move
    
    @discardableResult
    func moveChild(from: Int, to: Int) -> Bool
    {
        guard children.moveElement(from: from, to: to) else { return false }
        
        send(.didUpdateNode(.movedNode(from: from, to: to)))
        sendToRoot(.movedNode(children[to], from: from, to: to))
        
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
        let newNumber = numberOfLeafsRecursivelyCashed()
        
        guard newNumber != numberOfLeafs else { return }
        
        numberOfLeafs = newNumber
        parent?.updateNumberOfLeafs()
        
        send(.didChangeLeafNumber(numberOfLeafs))
    }
    
    func numberOfLeafsRecursivelyCashed() -> Int
    {
        if isLeaf { return 1 }
        
        var subitemLeafs = 0
        
        children.forEach { subitemLeafs += $0.numberOfLeafs }
        
        return subitemLeafs
    }
    
    func calculateNumberOfLeafs() -> Int
    {
        if isLeaf
        {
            numberOfLeafs = 1
        }
        else
        {
            var subitemLeafs = 0
            
            children.forEach { subitemLeafs += $0.calculateNumberOfLeafs() }
            
            numberOfLeafs = 1 + subitemLeafs
        }
        
        return numberOfLeafs
    }
    
    private(set) var numberOfLeafs = 1
    
    // MARK: - Root
    
    var isRoot: Bool { parent == nil }
    
    var indexInParent: Int? { parent?.index(of: self) }
    
    weak var parent: Node?
    {
        didSet
        {
            guard oldValue !== parent else { return }

            send(.didUpdateNode(.switchedParent(from: oldValue, to: parent)))
        }
    }
    
    // MARK: - Propagate Updates to Root
    
    private func sendToRoot(_ event: Event.TreeUpdate)
    {
        guard let parent = parent else
        {
            send(.didUpdateTree(event))
            return
        }
        
        parent.sendToRoot(event)
    }
    
    // MARK: - Observability
    
    private func send(_ update: Event) { treeMessenger.send(update) }
    
    let treeMessenger = TreeMessenger()
    
    class TreeMessenger: Observable
    {
        let messenger = Messenger<Event?>()
    }
    
    enum Event
    {
        case didUpdateTree(TreeUpdate)
        case didUpdateNode(NodeUpdate)
        case didChangeLeafNumber(Int)
        
        enum TreeUpdate // gets propagated to root (for observers of the whole tree)
        {
            case removedNodes([Node], from: Node)
            case insertedNodes([Node], in: Node, first: Int, last: Int)
            case movedNode(Node, from: Int, to: Int)
            case receivedMessage(Data.Message, fromDataIn: Node) // messages from node data
        }
        
        enum NodeUpdate // for observers of each respective node
        {
            var modifiesGraphStructure: Bool
            {
                switch self
                {
                case .removedNodes, .insertedNodes, .switchedParent: return true
                default: return false
                }
            }
            
            case switchedParent(from: Node?, to: Node?)
            case insertedNodes(first: Int, last: Int)
            case movedNode(from: Int, to: Int)
            case removedNodes([Node], from: [Int])
        }
    }
    
    // MARK: - Branches
    
    subscript(_ indexes: [Int]) -> [Node]
    {
        let result = children[indexes]
        
        if result.count != indexes.count
        {
            log(warning: "Tried to access at least 1 branch at invalid index.")
        }
        
        return result
    }
    
    subscript(_ index: Int?) -> Node?
    {
        children.at(index)
    }
    
    func sortWithoutSendingUpdate(comparator: (Node, Node) -> Bool)
    {
        children.sort(by: comparator)
        
        children.forEach
        {
            $0.sortWithoutSendingUpdate(comparator: comparator)
        }
    }
    
    func index(of child: Node) -> Int?
    {
        children.firstIndex { $0 === child }
    }
    
    var isLeaf: Bool { count == 0 }
    var count: Int { children.count }
    
    private(set) var children = [Node]()
    
    // MARK: - Node
    
    public typealias Node = Tree<Data>
}
