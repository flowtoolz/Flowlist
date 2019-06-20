import SwiftObserver

extension Record
{
    init(item: Item)
    {
        let data = item.data
        
        self.init(id: data.id,
                  text: data.text.value,
                  state: data.state.value,
                  tag: data.tag.value,
                  rootID: item.root?.data.id,
                  position: item.indexInRoot ?? 0)
    }
    
    func makeItem() -> Item
    {
        let data = ItemData(id: id)
        
        data.text <- text
        data.state <- state
        data.tag <- tag
        
        return Item(data: data)
    }
    
    static func makeRecordsRecursively(for item: Item, at position: Int? = nil) -> [Record]
    {
        // calling indexInRoot just once in the first call, so performance is ok
        let recPosition = position ?? (item.indexInRoot ?? 0)
        
        let data = item.data
        
        let record = Record(id: data.id,
                            text: data.text.value,
                            state: data.state.value,
                            tag: data.tag.value,
                            rootID: item.root?.data.id,
                            position: recPosition)
        
        var result = [record]
        
        for subPosition in 0 ..< item.count
        {
            guard let subItem = item[subPosition] else { continue }
            
            result += makeRecordsRecursively(for: subItem, at: subPosition)
        }
        
        return result
    }
}
