enum Direction
{
    case left, right
    
    var reverse: Direction { self == .left ? .right : .left }
}
