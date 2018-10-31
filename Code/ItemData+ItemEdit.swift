import SwiftObserver

extension ItemData
{
    convenience init(from editInfo: ItemEditInfo)
    {
        self.init(id: editInfo.id)
        
        text <- editInfo.text
        state <- editInfo.state
        tag <- editInfo.tag
    }
}
