import SwiftyToolz

struct Record: Codable, Equatable
{
    init(id: ID,
         text: String? = nil,
         state: ItemData.State? = nil,
         tag: ItemData.Tag? = nil,
         parent: ID?,
         position: Int)
    {
        self.id = id
        self.text = text
        self.state = state
        self.tag = tag
        self.parent = parent
        self.position = position
    }
    
    let id: ID
    
    let text: String?
    let state: ItemData.State?
    let tag: ItemData.Tag?
    
    let parent: ID?
    let position: Int
        
    typealias ID = String
}
