extension Tree where Data == ItemData
{
    func text(_ format: TextFormat) -> String
    {
        switch format
        {
        case .plain: return plainText()
        case .markdown: return markdown()
        }
    }
    
    func plainText(recursionDepth: Int = 0, prefix: String = "") -> String
    {
        var result = text ?? ""
            
        if recursionDepth == 0
        {
            result += "\n"
        }
        else if recursionDepth > 0 && count > 0
        {
            result = prefix + " " + result
        }
        
        var sectionNumber = 1
        
        for item in children
        {
            guard !item.isDone else { continue }
            
            var itemPrefix = prefix
            if itemPrefix.count > 0 { itemPrefix += "." }
            itemPrefix += "\(sectionNumber)"
            
            let isParagraph = item.isLeaf
            let breaks: String = "\n\n" + (isParagraph ? "" : "\n")
            let itemDepth = recursionDepth + 1
            
            result += breaks + item.plainText(recursionDepth: itemDepth,
                                              prefix: itemPrefix)
            
            sectionNumber += isParagraph ? 0 : 1
        }
        
        return result
    }
    
    func markdown(recursionDepth: Int = 0) -> String
    {
        var result = text ?? ""
        
        if !isLeaf && recursionDepth < 6
        {
            result = String(repeating: "#",
                            count: recursionDepth + 1) + " " + result
        }
        
        if subitemsAreBulletPoints()
        {
            result += "\n"
            
            children.forEach
            {
                guard !$0.isDone, let text = $0.text else { return }
                
                result += "\n* " + text
            }
        }
        else
        {
            children.forEach
            {
                guard !$0.isDone else { return }
                
                result += "\n\n" + $0.markdown(recursionDepth: recursionDepth + 1)
            }
        }
        return result
    }
    
    private func subitemsAreBulletPoints() -> Bool
    {
        var bulletPoints = 0
        
        for subitem in children
        {
            guard !subitem.isDone else { continue }
            
            if !subitem.isLeaf { return false }
            if (subitem.text ?? "").count > 100 { return false }
            
            bulletPoints += 1
        }
        
        return bulletPoints > 0
    }
}
