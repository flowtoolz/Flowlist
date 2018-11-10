enum Edit
{
    case insertItems(withModifications: [Modification], inItemWithID: String?)
    case modifyItem(withModification: Modification, inItemWithID: String?)
    case removeItems(withIDs: [String])
}
