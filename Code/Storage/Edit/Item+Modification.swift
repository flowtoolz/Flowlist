import SwiftObserver

extension Tree where Data == ItemData
{
    convenience init(modification: Modification)
    {
        let data = ItemData(id: modification.id)
        
        data.text <- modification.text
        data.state <- modification.state
        data.tag <- modification.tag
        
        self.init(data: data)
    }
    
    func modification(modifiesPosition: Bool = true) -> Modification
    {
        return Modification(id: data.id,
                            text: text,
                            state: data.state.value,
                            tag: data.tag.value,
                            rootID: root?.data.id,
                            position: indexInRoot ?? 0,
                            modifiesPosition: modifiesPosition)
    }
    
    /**
     This avoids all but one calls to indexInRoot, whose complexity would all be linear in the number of siblings.
     **/
    func modifications(position: Int? = nil) -> [Modification]
    {
        let modPosition = position ?? (indexInRoot ?? 0)
        
        let modification = Modification(id: data.id,
                                        text: text,
                                        state: data.state.value,
                                        tag: data.tag.value,
                                        rootID: root?.data.id,
                                        position: modPosition)
        
        var result = [modification]
        
        for index in 0 ..< count
        {
            guard let subitem = self[index] else { continue }
            
            let subModifications = subitem.modifications(position: index)
            
            result.append(contentsOf: subModifications)
        }
        
        return result
    }
}
