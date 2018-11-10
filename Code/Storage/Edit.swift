enum Edit
{
    case insertItems(withModifications: [Modification], inRootWithID: String?)
    case modifyItem(withModification: Modification, inRootWithID: String?)
    case removeItems(withIDs: [String])
}
