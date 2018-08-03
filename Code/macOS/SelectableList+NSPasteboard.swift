import AppKit
import SwiftObserver

extension SelectableList
{
    func pasteFromSystemPasteboard()
    {
        guard let tasks = tasksFromPasteboard() else { return }
        
        let index = newIndexBelowSelection
        
        guard root?.insert(tasks, at: index) ?? false else { return }
        
        let pastedIndexes = Array(index ..< index + tasks.count)
        
        selection.setWithTasksListed(at: pastedIndexes)
    }
    
    func tasksFromPasteboard() -> [Task]?
    {
        guard let string = NSPasteboard.general.string(forType: .string) else
        {
            return nil
        }
        
        return Task.from(pasteboardString: string)
    }
}

var systemPasteboardHasText: Bool
{
    return NSPasteboard.general.string(forType: .string) != nil
}
