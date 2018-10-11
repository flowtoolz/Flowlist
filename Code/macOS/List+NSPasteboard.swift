import AppKit
import SwiftObserver

extension List
{
    func pasteFromSystemPasteboard()
    {
        guard let string = NSPasteboard.general.string(forType: .string),
            let items = Item.from(pasteboardString: string)
        else
        {
            return
        }
        
        paste(items)
    }
}

var systemPasteboardHasText: Bool
{
    return NSPasteboard.general.string(forType: .string) != nil
}
