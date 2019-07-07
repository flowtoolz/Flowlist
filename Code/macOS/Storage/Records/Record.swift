import SwiftyToolz

struct Record: Codable, Equatable
{
    init(id: ID,
         text: String? = nil,
         state: ItemData.State? = nil,
         tag: ItemData.Tag? = nil,
         rootID: ID?,
         position: Int)
    {
        self.id = id
        self.text = text
        self.state = state
        self.tag = tag
        self.rootID = rootID
        self.position = position
    }
    
    let id: ID
    
    let text: String?
    let state: ItemData.State?
    let tag: ItemData.Tag?
    
    let rootID: ID?
    let position: Int
    
    enum Field: String, CaseIterable
    {
        case text, state, tag, root, position
    }
    
    typealias ID = String
}
