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
        let item = Node(data: ItemData())
        
        let belowIsInProgress = self[index]?.isInProgress ?? false
        let aboveIsInProgress = index == 0 || (self[index - 1]?.isInProgress ?? false)
        
        item.data?.state <- belowIsInProgress && aboveIsInProgress ? .inProgress : nil
        
        guard insert(item, at: index) else { return nil }
        
        send(.did(.wantTextInput(at: index)))
        
        return item
    }
}
