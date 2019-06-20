import SwiftObserver

extension Tree where Data == ItemData
{
    convenience init(record: Record)
    {
        let data = ItemData(id: record.id)
        
        data.text <- record.text
        data.state <- record.state
        data.tag <- record.tag
        
        self.init(data: data)
    }
    
    func makeRecord() -> Record
    {
        return Record(id: data.id,
                      text: text,
                      state: data.state.value,
                      tag: data.tag.value,
                      rootID: root?.data.id,
                      position: indexInRoot ?? 0)
    }
    
    func makeRecordsRecursively(position: Int? = nil) -> [Record]
    {
        // calling indexInRoot just once in the first call, so performance is ok
        let recPosition = position ?? (indexInRoot ?? 0)
        
        let record = Record(id: data.id,
                            text: text,
                            state: data.state.value,
                            tag: data.tag.value,
                            rootID: root?.data.id,
                            position: recPosition)
        
        var result = [record]
        
        for index in 0 ..< count
        {
            guard let subitem = self[index] else { continue }
            
            let subRecords = subitem.makeRecordsRecursively(position: index)
            
            result.append(contentsOf: subRecords)
        }
        
        return result
    }
}