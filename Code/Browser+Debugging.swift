extension Browser
{
    var description: String
    {
        var desc = ""
        
        for i in 0 ..< numberOfLists
        {
            guard let list = list(at: i) else { continue }
            
            desc += "\(i): "
            desc += list.title.observable?.value ?? "untitled"
            desc += "\n"
        }
        
        return desc
    }
}
