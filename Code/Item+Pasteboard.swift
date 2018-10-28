extension Tree where Data == ItemData
{
    static func from(pasteboardString string: String) -> [Item]?
    {
        var texts = string.components(separatedBy: .newlines)
        
        texts = texts.map
        {
            var text = $0
            
            while !startCharacters.contains(text.first ?? "a")
            {
                text.removeFirst()
            }
            
            while text.last == " "
            {
                text.removeLast()
            }
            
            return text
        }
        
        texts.remove { $0.count < 2 }
        
        let result = texts.map { Item($0) }
        
        return result.isEmpty ? nil : result
    }
}

fileprivate let startCharacters: String =
{
    var characters = "abcdefghijklmnopqrstuvwxyzöäü"
    characters += characters.uppercased()
    characters += "0123456789"
    return characters
}()
