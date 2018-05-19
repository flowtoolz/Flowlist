import AppKit

extension NSEvent
{
    var key: Key
    {
        return Key(rawValue: keyCode) ?? .unknown
    }
    
    enum Key: UInt16
    {
        case unknown
        case enter = 36
        case space = 49
        case delete = 51
        case left = 123
        case right = 124
        case down = 125
        case up = 126
    }
}
