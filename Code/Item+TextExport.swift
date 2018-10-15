extension Tree where Data == ItemData
{
    var text: String
    {
        var result = title ?? ""
        
        for branch in branches
        {
            result += "\n\n" + branch.text
        }
        
        return result
    }
}
