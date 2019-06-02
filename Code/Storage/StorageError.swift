extension Error
{
    var storageError: StorageError
    {
        if let error = self as? StorageError
        {
            return error
        }
        else
        {
            let message = "This issue came up: \(self.localizedDescription)"
            return StorageError.message(message)
        }
    }
}

enum StorageError: Error, CustomDebugStringConvertible
{
    var debugDescription: String
    {
        return message
    }
    
    var message: String
    {
        switch self
        {
        case .message(let text): return text
        }
    }
    
    case message(_ text: String)
}
