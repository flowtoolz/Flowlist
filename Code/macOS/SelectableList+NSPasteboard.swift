import AppKit
import SwiftObserver

extension SelectableList
{
    func pasteFromSystemPasteboard()
    {
        guard let string = NSPasteboard.general.string(forType: .string),
            let tasks = Task.from(pasteboardString: string)
        else
        {
            return
        }
        
        paste(tasks)
    }
}

var systemPasteboardHasText: Bool
{
    return NSPasteboard.general.string(forType: .string) != nil
}
