enum Edit
{
    case updateItems(withModifications: [Modification])
    case removeItems(withIDs: [String])
}
