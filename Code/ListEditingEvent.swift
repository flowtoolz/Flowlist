enum ListEditingEvent
{
    case didNothing
    case didMoveItem(from: Int, to: Int)
    case didInsertItem(index: Int)
    case didRemoveItems(indexes: [Int])
}
