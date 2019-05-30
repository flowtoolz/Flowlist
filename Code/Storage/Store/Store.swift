import PromiseKit
import SwiftObserver
import SwiftyToolz

class Store: Observer, CustomObservable
{
    // MARK: - Initialization
    
    static let shared = Store() 
    
    private init() {}

    // MARK: - Update Root
    
    func update(root newRoot: Item)
    {
        stopObserving(root?.treeMessenger)
        observeTreeMessenger(of: newRoot)
        itemHash.reset(with: newRoot.array)
        updateUserCreatedLeafs(with: newRoot)
        
        root = newRoot
        
        pasteWelcomeTourIfRootIsEmpty()
        
        send(.didSwitchRoot)
    }
    
    private func observeTreeMessenger(of newRoot: Item)
    {
        observe(newRoot.treeMessenger)
        {
            [weak self, weak newRoot] event in
            
            guard let newRoot = newRoot else { return }
            
            self?.didReceive(event, from: newRoot)
        }
    }
    
    private func didReceive(_ event: Item.Event, from root: Item)
    {
        switch event
        {
        case .didNothing: break
            
        case .didUpdateNode(let edit):
            if edit.modifiesGraphStructure
            {
                updateUserCreatedLeafs(with: root)
            }
            
        case .didChangeLeafNumber(_):
            updateUserCreatedLeafs(with: root)
            
        case .didUpdateTree(let treeUpdate):
            switch treeUpdate
            {
            case .insertedNodes(let items, _, _):
                var hadAlreadyAddedAll = true
                
                for item in items
                {
                    if itemHash[item.data.id] == nil
                    {
                        hadAlreadyAddedAll = false
                        itemHash.add(item.array)
                    }
                }
                
                if !hadAlreadyAddedAll
                {
                    send(.didUpdate(treeUpdate))
                }
                
            case .receivedMessage, .movedNode:
                // TODO: avoid sending updates back that were triggered from outside (from database)
                send(.didUpdate(treeUpdate))
                
            case .removedNodes(let items, _):
                var hadAlreadyRemovedAll = true
                
                for item in items
                {
                    if itemHash[item.data.id] != nil
                    {
                        hadAlreadyRemovedAll = false
                        itemHash.remove(item.array)
                    }
                }
                
                if !hadAlreadyRemovedAll
                {
                    send(.didUpdate(treeUpdate))
                }
            }
        }
    }
    
    // MARK: - Welcome Tour
    
    func pasteWelcomeTourIfRootIsEmpty()
    {
        guard let root = self.root else
        {
            log(warning: "Root is nil.")
            return
        }
        
        if root.isLeaf
        {
            DispatchQueue.main.async
            {
                root.insert(Item.welcomeTour, at: 0)
            }
        }
    }
    
    // MARK: - Track Number of User Created Leafs
    
    private func updateUserCreatedLeafs(with root: Item)
    {
        numberOfUserCreatedLeafs <- root.isLeaf ? 0 : root.numberOfLeafs
    }
    
    let numberOfUserCreatedLeafs = Var(0)
    
    // MARK: - Item Storage
    
    private(set) var root: Item?
    let itemHash = HashMap()
    
    // MARK: - Observability
    
    typealias Message = Event
    
    let messenger = Messenger(Event.didNothing)
    
    enum Event
    {
        case didNothing, didSwitchRoot, didUpdate(Item.Event.TreeUpdate)
    }
}
