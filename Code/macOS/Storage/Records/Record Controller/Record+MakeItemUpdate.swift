extension Record
{
    func makeUpdate() -> ItemStore.Update
    {
        let data = ItemData(id: id)
        data.text.value = text
        data.state.value = state
        data.tag.value = tag
        return ItemStore.Update(data: data, parentID: rootID, position: position)
    }
}
