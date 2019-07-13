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
                  rootID: item.parentID,
                  position: item.position)
    }
    
    static func makeRecordsRecursively(for item: Item?, at position: Int? = nil) -> [Record]
    {
        guard let item = item else { return [] }
        
        // calling indexInRoot just once in the first call, so performance is ok
        let recPosition = position ?? item.position
        
        let data = item.data
        
        let record = Record(id: data.id,
                            text: data.text.value,
                            state: data.state.value,
                            tag: data.tag.value,
                            rootID: item.parentID,
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

