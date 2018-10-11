import AppKit
import SwiftObserver

extension List
{
    func pasteFromSystemPasteboard()
    {
        guard let string = NSPasteboard.general.string(forType: .string),
            let tasks = Item.from(pasteboardString: string)
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
