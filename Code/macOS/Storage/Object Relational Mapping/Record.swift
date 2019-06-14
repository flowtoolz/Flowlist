import SwiftyToolz

extension Array where Element == Record
{
    var byRootID: [String : [Record]]
    {
        var resultDictionary = [String : [Record]]()
        
        for record in self
        {
            guard let rootID = record.rootID else
            {
                log(error: "Item record has no root ID.")
                continue
            }
            
            if resultDictionary[rootID] == nil
            {
                resultDictionary[rootID] = [Record]()
            }
            
            resultDictionary[rootID]?.append(record)
        }
        
        return resultDictionary
    }
}

struct Record
{
    init(id: String,
         text: String? = nil,
         state: ItemData.State? = nil,
         tag: ItemData.Tag? = nil,
         rootID: String?,
         position: Int)
    {
        self.id = id
        self.text = text
        self.state = state
        self.tag = tag
        self.rootID = rootID
        self.position = position
    }
    
    let id: String
    
    let text: String?
    let state: ItemData.State?
    let tag: ItemData.Tag?
    
    let rootID: String?
    let position: Int
    
    enum Field: String, CaseIterable
    {
        case text, state, tag, root, position
    }
}
