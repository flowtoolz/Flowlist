import UniformTypeIdentifiers

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
    
    var uti: UTType
    {
        switch self
        {
        case .plain: return .plainText
        case .markdown: return .text
        }
    }
}
