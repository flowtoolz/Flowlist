struct Modification
{
    init(id: String,
         text: String? = nil,
         state: ItemData.State? = nil,
         tag: ItemData.Tag? = nil,
         rootId: String? = nil,
         modified: [Field] = Field.allCases)
    {
        self.id = id
        self.text = text
        self.state = state
        self.tag = tag
        self.rootId = rootId
        self.modified = modified
    }
    
    let id: String
    let text: String?
    let state: ItemData.State?
    let tag: ItemData.Tag?
    let rootId: String?
    let modified: [Field]
    
    enum Field: String, CaseIterable
    {
        case text, state, tag, root
    }
}
