struct Modification
{
    init(id: String,
         text: String? = nil,
         state: ItemData.State? = nil,
         tag: ItemData.Tag? = nil,
         position: Int,
         modifiesPosition: Bool = true)
    {
        self.id = id
        self.text = text
        self.state = state
        self.tag = tag
        self.position = position
        self.modifiesPosition = modifiesPosition
    }
    
    let id: String
    let text: String?
    let state: ItemData.State?
    let tag: ItemData.Tag?
    let position: Int
    let modifiesPosition: Bool
    
    enum Field: String, CaseIterable
    {
        case text, state, tag, position
    }
}
