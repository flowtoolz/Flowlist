import SwiftObserver

typealias Item = Tree<ItemData>

extension Tree where Data == ItemData
{
    @discardableResult
    func createSubitem(at index: Int) -> Node?
    {
        let item = Node()
        
        let belowIsInProgress = self[index]?.isInProgress ?? false
        let aboveIsInProgress = index == 0 || (self[index - 1]?.isInProgress ?? false)
        
        item.data?.state <- belowIsInProgress && aboveIsInProgress ? .inProgress : nil
        
        guard insert(item, at: index) else { return nil }
        
        send(.did(.wantTextInput(at: index)))
        
        return item
    }
    
    convenience init(_ title: String? = nil)
    {
        let newData = ItemData()
        newData.title = Var(title)
        
        self.init(data: newData)
    }
}
