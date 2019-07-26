extension Record
{
    func makeUpdate() -> Update
    {
        let data = ItemData(id: id)
        data.text.value = text
        data.state.value = state
        data.tag.value = tag
        return Update(data: data, parentID: parent, position: position)
    }
}
