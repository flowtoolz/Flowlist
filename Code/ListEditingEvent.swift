enum ListEditingEvent: Equatable
{
    case didNothing
    case didMoveItem(from: Int, to: Int)
    case didInsertItems(at: [Int])
    case didRemoveItems(at: [Int])
}
