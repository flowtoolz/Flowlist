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
    
    func plainText(recursionDepth: Int = 0,
                   titlePrefix: String = "") -> String
    {
        var result = title ?? ""
            
        if recursionDepth == 0
        {
            result += "\n"
        }
        else if recursionDepth > 0 && count > 0
        {
            result = titlePrefix + " " + result
        }
        
        var sectionNumber = 1
        
        for item in branches
        {
            guard !item.isDone else { continue }
            
            var itemTitleRefix = titlePrefix
            if itemTitleRefix.count > 0 { itemTitleRefix += "." }
            itemTitleRefix += "\(sectionNumber)"
            
            let isParagraph = item.isLeaf
            let breaks: String = "\n\n" + (isParagraph ? "" : "\n")
            let itemDepth = recursionDepth + 1
            
            result += breaks + item.plainText(recursionDepth: itemDepth,
                                         titlePrefix: itemTitleRefix)
            
            sectionNumber += isParagraph ? 0 : 1
        }
        
        return result
    }
    
    func markdown(recursionDepth: Int = 0) -> String
    {
        var result = title ?? ""
        
        if !isLeaf
        {
            result = String(repeating: "#",
                            count: recursionDepth + 1) + " " + result
        }
        
        for item in branches
        {
            guard !item.isDone else { continue }
            
            result += "\n\n" + item.markdown(recursionDepth: recursionDepth + 1)
        }
        
        return result
    }
}
