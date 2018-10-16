extension Tree where Data == ItemData
{
    func text(recursionDepth: Int = 0,
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
            var itemTitleRefix = titlePrefix
            if itemTitleRefix.count > 0 { itemTitleRefix += "." }
            itemTitleRefix += "\(sectionNumber)"
            
            let isParagraph = item.isLeaf
            let breaks: String = "\n\n" + (isParagraph ? "" : "\n")
            let itemDepth = recursionDepth + 1
            
            result += breaks + item.text(recursionDepth: itemDepth,
                                         titlePrefix: itemTitleRefix)
            
            sectionNumber += isParagraph ? 0 : 1
        }
        
        return result
    }
}
