extension Browser
{
    var description: String
    {
        var desc = ""
        
        for i in 0 ..< numberOfLists
        {
            guard let list = self[i] else { continue }
            
            desc += "\(i): "
            desc += list.title.source.value ?? "untitled"
            desc += "\n"
        }
        
        return desc
    }
}
