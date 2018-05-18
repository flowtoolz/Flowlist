enum ListEditingEvent
{
    case didNothing
    case didMoveItem(from: Int, to: Int)
    case didInsertItem(at: Int)
    case didRemoveItems(at: [Int])
}
