extension Error
{
    var readable: ReadableError
    {
        if let readableError = self as? ReadableError
        {
            return readableError
        }
        else
        {
            return .message(localizedDescription)
        }
    }
}

enum ReadableError: Error, CustomDebugStringConvertible
{
    var localizedDescription: String
    {
        return message
    }
    
    var debugDescription: String
    {
        return message
    }
    
    var message: String
    {
        switch self
        {
        // TODO: can we make this more readable with https://github.com/mxcl/LegibleError ?
        case .message(let text): return text
        }
    }
    
    case message(_ text: String)
}
