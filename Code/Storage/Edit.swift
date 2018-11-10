enum Edit
{
    case insertItems([Modification], inItemWithId: String?)
    case modifyItem(Modification, inItemWithId: String?)
    case removeItemsWithIds([String])
}
