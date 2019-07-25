extension Array where Element == Update
{
    var sortedByPosition: [Update]
    {
        return sorted { $0.position < $1.position }
    }
}

struct Update
{
    func wouldChange(_ item: Item) -> Bool
    {
        if item.id != data.id { return false }
        if item.data != data { return false }
        if item.position != position { return false }
        if item.parentID != parent { return false }
        return true
    }
    
    let data: ItemData
    let parent: ItemData.ID?
    let position: Int
}
