struct Modification
{
    init(id: String,
         text: String? = nil,
         state: ItemData.State? = nil,
         tag: ItemData.Tag? = nil,
         rootID: String?,
         position: Int,
         modifiesPosition: Bool = true)
    {
        self.id = id
        self.text = text
        self.state = state
        self.tag = tag
        self.rootID = rootID
        self.position = position
        self.modifiesPosition = modifiesPosition
    }
    
    let id: String
    let text: String?
    let state: ItemData.State?
    let tag: ItemData.Tag?
    let rootID: String?
    let position: Int
    let modifiesPosition: Bool
    
    enum Field: String, CaseIterable
    {
        case text, state, tag, root, position
    }
}
