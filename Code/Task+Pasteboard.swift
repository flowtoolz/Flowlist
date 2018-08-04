extension Task
{
    static func from(pasteboardString string: String) -> [Task]?
    {
        var titles = string.components(separatedBy: .newlines)
        
        titles = titles.map
        {
            var title = $0
            
            while !startCharacters.contains(title.first ?? "a")
            {
                title.removeFirst()
            }
            
            while title.last == " "
            {
                title.removeLast()
            }
            
            return title
        }
        
        titles.remove { $0.count < 2 }
        
        let result = titles.map { Task($0) }
        
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
