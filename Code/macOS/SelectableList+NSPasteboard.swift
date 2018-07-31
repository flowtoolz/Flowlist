import AppKit
import SwiftObserver

extension SelectableList
{
    func pasteFromSystemPasteboard()
    {
        let tasks = tasksFromPasteboard()
        let index = newIndexBelowSelection
        
        guard root?.insert(tasks, at: index) ?? false else { return }
        
        let pastedIndexes = Array(index ..< index + tasks.count)
        
        selection.setWithTasksListed(at: pastedIndexes)
    }
    
    func tasksFromPasteboard() -> [Task]
    {
        let pasteboard = NSPasteboard.general
        
        guard let string = pasteboard.string(forType: .string) else
        {
            return []
        }
        
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
        
        return titles.map { Task(title: $0) }
    }
}

var systemPasteboardHasText: Bool
{
    return NSPasteboard.general.string(forType: .string) != nil
}

fileprivate let startCharacters: String =
{
    var characters = "abcdefghijklmnopqrstuvwxyzöäü"
    characters += characters.uppercased()
    characters += "0123456789"
    return characters
}()
