import SwiftObserver

extension Tree where Data == ItemData
{
    convenience init(from modification: Modification)
    {
        let data = ItemData(id: modification.id)
        
        data.text <- modification.text
        data.state <- modification.state
        data.tag <- modification.tag
        
        self.init(data: data)
    }
    
    var modification: Modification
    {
        return Modification(id: data.id,
                            text: text,
                            state: data.state.value,
                            tag: data.tag.value,
                            rootId: root?.data.id)
    }
}
