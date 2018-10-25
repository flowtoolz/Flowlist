enum TextFormat: String
{
    case plain = "Plain Text", markdown = "Markdown"
    
    static var all: [TextFormat] { return [.plain, .markdown] }
    
    var fileExtension: String
    {
        switch self
        {
        case .plain: return "txt"
        case .markdown: return "md"
        }
    }
}
