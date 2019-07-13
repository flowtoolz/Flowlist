extension Record
{
    func makeUpdate() -> ItemUpdate
    {
        let data = ItemData(id: id)
        data.text.value = text
        data.state.value = state
        data.tag.value = tag
        return ItemUpdate(data: data, parentID: rootID, position: position)
    }
}
