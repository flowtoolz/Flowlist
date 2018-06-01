enum Direction
{
    case left, right
    
    var reverse: Direction { return self == .left ? .right : .left }
}
