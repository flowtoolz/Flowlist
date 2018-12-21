enum Edit
{
    case updateItems(withRecords: [Record])
    case removeItems(withIDs: [String])
}
