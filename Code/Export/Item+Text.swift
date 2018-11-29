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
        
        for item in branches
        {
            guard !item.isDone else { continue }
            
            var itemRefix = prefix
            if itemRefix.count > 0 { itemRefix += "." }
            itemRefix += "\(sectionNumber)"
            
            let isParagraph = item.isLeaf
            let breaks: String = "\n\n" + (isParagraph ? "" : "\n")
            let itemDepth = recursionDepth + 1
            
            result += breaks + item.plainText(recursionDepth: itemDepth,
                                              prefix: itemRefix)
            
            sectionNumber += isParagraph ? 0 : 1
        }
        
        return result
    }
    
    func markdown(recursionDepth: Int = 0) -> String
    {
        var result = text ?? ""
        
        if !isLeaf
        {
            result = String(repeating: "#",
                            count: recursionDepth + 1) + " " + result
        }
        
        branches.forEach
        {
            guard !$0.isDone else { return }
            
            result += "\n\n" + $0.markdown(recursionDepth: recursionDepth + 1)
        }
        
        return result
    }
}
