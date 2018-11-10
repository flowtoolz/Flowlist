struct Modification
{
    init(id: String,
         text: String? = nil,
         state: ItemData.State? = nil,
         tag: ItemData.Tag? = nil,
         rootId: String? = nil,
         position: Int? = nil)
    {
        self.id = id
        self.text = text
        self.state = state
        self.tag = tag
        self.rootId = rootId
        self.position = position
    }
    
    let id: String
    let text: String?
    let state: ItemData.State?
    let tag: ItemData.Tag?
    let rootId: String?
    let position: Int?
    
    enum Field: String, CaseIterable
    {
        case text, state, tag, root, position
    }
}
