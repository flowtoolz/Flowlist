extension Error
{
    var message: String
    {
        if let error = self as? StorageError
        {
            switch error
            {
            case .message(let text): return text
            }
        }
        else
        {
            return "This issue came up: \(String(describing: self))"
        }
    }
}

enum StorageError: Error
{
    case message(_ text: String)
}
