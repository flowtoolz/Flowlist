import SwiftObserver

extension ItemData
{
    convenience init(from editInfo: Item.EditInfo)
    {
        self.init(id: editInfo.id)
        
        text <- editInfo.text
        state <- editInfo.state
        tag <- editInfo.tag
    }
}
