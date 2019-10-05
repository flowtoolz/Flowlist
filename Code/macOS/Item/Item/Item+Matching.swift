extension Tree where Data == ItemData
{
    func isIdentical(to item: Item) -> Bool
    {
        guard count == item.count,
            data.isIdentical(to: item.data)
        else
        {
            return false
        }
        
        for index in 0 ..< count
        {
            guard let mySubitem = self[index],
                let otherSubitem = item[index],
                mySubitem.isIdentical(to: otherSubitem)
            else
            {
                return false
            }
        }
        
        return true
    }
}

extension ItemData
{
    func isIdentical(to data: ItemData) -> Bool
    {
        id == data.id && self == data
    }
}
