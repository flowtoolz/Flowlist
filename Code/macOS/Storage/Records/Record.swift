import SwiftyToolz

struct Record: Codable, Equatable
{
    let id: ID
    
    let text: String?
    let state: ItemData.State?
    let tag: ItemData.Tag?
    
    let parent: ID?
    let position: Int
        
    typealias ID = String
}
