import SwiftObserver
import PromiseKit
import SwiftyToolz

class TreeSelector: Observer, CustomObservable
{
    // MARK: - Life Cycle
    
    static let shared = TreeSelector()
    private init() { observeTreeStore() }
    deinit { stopObserving() }
    
    // MARK: - Observe Tree Store
    
    private func observeTreeStore()
    {
        observe(TreeStore.shared)
        {
            [weak self] event in event.forSome(self?.treeStoreDidSend)
        }
    }
    
    private func treeStoreDidSend(_ event: TreeStore.Event)
    {
        switch event
        {
        case .treeDidUpdate:
            break
            
        case .willApplyMultipleUpdates:
            treeStoreWillApplyMultipleUpdates()
            
        case .didApplyMultipleUpdates:
            treeStoreDidApplyMultipleUpdates()
            
        case .didAddTree(let newTree):
            if treeStoreIsDoingBatchUpdate
            {
                treesFoundDuringBatchUpdate.append(newTree)
            }
            else
            {
                didFind(newTree)
            }
            
        case .didRemoveTree(let removedTree):
            if treeStoreIsDoingBatchUpdate
            {
                treesRemovedDuringBatchUpdate.append(removedTree)
            }
            else
            {
                didRemove(removedTree)
            }
        }
    }
    
    // MARK: - Multiple Tree Changes During Batch Updates
    
    private func treeStoreWillApplyMultipleUpdates()
    {
        treeStoreIsDoingBatchUpdate = true
        
        treesFoundDuringBatchUpdate.removeAll()
        treesRemovedDuringBatchUpdate.removeAll()
    }
    
    private func treeStoreDidApplyMultipleUpdates()
    {
        treeStoreIsDoingBatchUpdate = false
        
        treesRemovedDuringBatchUpdate.forEach { didRemove($0) }
        treesRemovedDuringBatchUpdate.removeAll()
        
        treesFoundDuringBatchUpdate.forEach { didFind($0) }
        treesFoundDuringBatchUpdate.removeAll()
    }
    
    private var treeStoreIsDoingBatchUpdate = false
    private var treesFoundDuringBatchUpdate = [Item]()
    private var treesRemovedDuringBatchUpdate = [Item]()
    
    // MARK: - Single Tree Changes
    
    private func didRemove(_ removedTree: Item)
    {
        if selectedTree === removedTree { select(nil) }
    }
    
    private func didFind(_ newTree: Item)
    {
        guard let selectedTree = selectedTree else { return select(newTree) }
        
        guard newTree !== selectedTree else { return }
        
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
        .catch { log(error: $0.readable.message) }
    }
    
    // MARK: - Select Tree
    
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
        observe(tree.treeMessenger).unwrap()
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
        case .didUpdateTree:
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
        "\(text ?? "Untitled") (\(numberOfLeafs) leaf\(numberOfLeafs != 1 ? "s" : ""))"
    }
}
