import SwiftObserver

extension Item
{
    convenience init(from modification: Modification)
    {
        let data = ItemData(id: modification.id)
        
        data.text <- modification.text
        data.state <- modification.state
        data.tag <- modification.tag
        
        self.init(data: data)
    }
}
