import SwiftObserver

typealias Item = Tree<ItemData>

extension Tree where Data == ItemData
{
    @discardableResult
    func createSubitem(at index: Int) -> Node?
    {
        let item = Node()
        
        let belowIsInProgress = count == index ? false : (self[index]?.isInProgress ?? false)
        let aboveIsInProgress = index == 0 || (self[index - 1]?.isInProgress ?? false)
        
        item.data?.state <- belowIsInProgress && aboveIsInProgress ? .inProgress : nil
        
        item.data?.wantsTextInput = true
        
        guard insert(item, at: index) else { return nil }
        
        return item
    }
    
    func edit() { data?.edit() }
    
    convenience init(_ title: String? = nil)
    {
        let newData = ItemData()
        newData.title = Var(title)
        
        self.init(data: newData)
    }
    
    func deselectAll()
    {
        for item in branches
        {
            item.isSelected = false
        }
    }
    
    var title: String? { return data?.title.value }
    
    var isSelected: Bool
    {
        get { return data?.isSelected.value ?? false }
        set { data?.isSelected <- newValue }
    }
    
    var isFocused: Bool
    {
        get { return data?.isFocused.value ?? false }
        set { data?.isFocused <- newValue }
    }

}
