import SwiftObserver

extension Tree where Data == ItemData
{
    @discardableResult
    func createSubitem(at index: Int) -> Item?
    {
        let data = ItemData()
        
        data.wantsTextInput = true // TODO: set this as initial value?
        
        let belowIsInProgress = count == index ? false : (self[index]?.isInProgress ?? false)
        
        let aboveIsInProgress = index == 0 || (self[index - 1]?.isInProgress ?? false)
        
        if belowIsInProgress && aboveIsInProgress
        {
            data.state <- .inProgress
        }
        
        let item = Item(data: data)
        
        guard insert(item, at: index) else { return nil }
        
        return item
    }
    
    convenience init(text: String? = nil)
    {
        let newData = ItemData()
        newData.text <- text
        
        self.init(data: newData)
    }
}
