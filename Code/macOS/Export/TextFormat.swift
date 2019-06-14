enum TextFormat: String, CaseIterable
{
    case plain = "Plain Text", markdown = "Markdown"
    
    var fileExtension: String
    {
        switch self
        {
        case .plain: return "txt"
        case .markdown: return "md"
        }
    }
}
