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
        guard id == data.id,
            tag.value == data.tag.value,
            text.value == data.text.value,
            state.value == data.state.value
        else
        {
            return false
        }
        
        return true
    }
}
