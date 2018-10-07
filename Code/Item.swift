import SwiftObserver

typealias Item = Tree<ItemData>

extension Tree where Data == ItemData
{
    convenience init(_ title: String? = nil,
                     state: ItemData.State? = nil,
                     tag: ItemData.Tag? = nil,
                     root: Node? = nil,
                     numberOfLeafs: Int = 1)
    {
        let newData = ItemData()
        
        newData.title = Var(title)
        newData.state = Var(state)
        newData.tag = Var(tag)
        
        self.init(data: newData, root: root, numberOfLeafs: numberOfLeafs)
    }
    
    @discardableResult
    func create(at index: Int) -> Node?
    {
        let taskBelowIsInProgress: Bool =
        {
            guard self[index] != nil else { return false }
            
            return self[index]?.isInProgress ?? false
        }()
        
        let taskAboveIsInProgress: Bool =
        {
            guard index > 0 else { return true }
            
            return self[index - 1]?.isInProgress ?? false
        }()
        
        let shouldBeInProgress = taskBelowIsInProgress && taskAboveIsInProgress
        
        let newSubtask = Node()
        newSubtask.data = ItemData()
        newSubtask.data?.state <- shouldBeInProgress ? .inProgress : nil
        
        guard insert(newSubtask, at: index) else { return nil }
        
        updateNumberOfLeafs()
        
        send(.did(.wantTextInput(at: index)))
        
        return newSubtask
    }
}
