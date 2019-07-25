import SwiftObserver
import PromiseKit
import SwiftyToolz

class TreeSelector: Observer, CustomObservable
{
    // MARK: - Initialization
    
    static let shared = TreeSelector()
    
    private init()
    {
        observe(TreeStore.shared)
        {
            [weak self] in if let event = $0 { self?.treeStoreDidSend(event) }
        }
    }
    
    // MARK: - Select Tree
    
    private func treeStoreDidSend(_ event: TreeStore.Event)
    {
        switch event
        {
        case .treeDidUpdate: break
        case .didAddTree(let newTree): didFind(newTree)
        case .didRemoveTree(let tree): if selectedTree === tree { select(nil) }
        }
    }
    
    private func didFind(_ newTree: Item)
    {
        guard let selectedTree = selectedTree else { return select(newTree) }
        
        guard newTree !== selectedTree else { return }
        
        // FIXME: the number of leafs isn't necessarily correct since trees are being built incrementally from updates...when a root is found it hasn't necessarily all its recursive children
        let keepSelectedTree = selectedTree.treeDescription
        let useNewTree = newTree.treeDescription
    
        let question = Dialog.Question(title: "Found Another Item Tree (Hierarchy)",
                                       text: "Multiple trees can exist for instance when another device has already saved items to iCloud.\n\nChoose one tree to work with, Flowlist will delete the other:",
                                       options: [useNewTree, keepSelectedTree])
    
        firstly
        {
            Dialog.default.pose(question, imageName: "icloud_conflict")
        }
        .done
        {
            if $0.options.first == useNewTree
            {
                self.select(nil)
                TreeStore.shared.deleteItems(with: [selectedTree.id])
                self.select(newTree)
            }
            else
            {
                TreeStore.shared.deleteItems(with: [newTree.id])
            }
        }
        .catch(log)
    }
    
    private func select(_ tree: Item?)
    {
        stopObserving(selectedTree?.treeMessenger)

        if let tree = tree
        {
            observeTreeMessenger(of: tree)
            updateUserCreatedLeafs(with: tree)
        }
        else
        {
            numberOfUserCreatedLeafs <- 0
        }
        
        selectedTree = tree
        DispatchQueue.main.async { self.send(tree) }
    }
    
    private(set) weak var selectedTree: Item?
    
    // MARK: - Track Number of User Created Leafs in Selected Root
    
    private func observeTreeMessenger(of tree: Item)
    {
        observe(tree.treeMessenger)
        {
            [weak self, weak tree] event in
            
            guard let tree = tree else { return }
            
            self?.didReceive(event, from: tree)
        }
    }
    
    private func didReceive(_ event: Item.Event, from tree: Item)
    {
        switch event
        {
        case .didNothing, .didUpdateTree:
            break
            
        case .didUpdateNode(let edit):
            if edit.modifiesGraphStructure
            {
                updateUserCreatedLeafs(with: tree)
            }
            
        case .didChangeLeafNumber(_):
            updateUserCreatedLeafs(with: tree)
        }
    }
    
    private func updateUserCreatedLeafs(with tree: Item)
    {
        numberOfUserCreatedLeafs <- tree.isLeaf ? 0 : tree.numberOfLeafs
    }
    
    let numberOfUserCreatedLeafs = Var(0)
    
    // MARK: - Observability
    
    let messenger = Messenger<Message>()
    typealias Message = Item?
}

private extension Item
{
    var treeDescription: String
    {
        return "\(text ?? "Untitled") (\(numberOfLeafs) leaf\(numberOfLeafs != 1 ? "s" : ""))"
    }
}
