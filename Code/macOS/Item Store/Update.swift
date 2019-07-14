struct Update
{
    func wouldChange(_ item: Item) -> Bool
    {
        if item.id != data.id { return false }
        if item.data != data { return false }
        if item.position != position { return false }
        if item.parentID != parentID { return false }
        return true
    }
    
    let data: ItemData
    let parentID: ItemData.ID?
    let position: Int
}
