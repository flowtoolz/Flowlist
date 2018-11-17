enum Edit
{
    case insertItems(withModifications: [Modification], inRootWithID: String?)
    case modifyItem(withModification: Modification)
    case removeItems(withIDs: [String])
}
