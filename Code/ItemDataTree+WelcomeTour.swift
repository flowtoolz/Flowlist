import SwiftObserver

extension Tree where Data == ItemData
{
    static var welcomeTour: [ItemDataTree]
    {
        var tour = [ItemDataTree]()
        
        tour.append(Item(text: "Welcome to Flowlist!"))
        tour[0].data.state <- .inProgress
        tour.append(Item(text: "Best select and edit with your keyboard"))
        tour[1].data.state <- .inProgress
        tour.append(Item(text: "The menus show all applicable commands in every situation"))
        
        // select
        
        let selectCommands = Item(text: "Move with the arrows: ↑ ↓ ← →")
        
        selectCommands.data.tag <- .red
        
        selectCommands.add(Item(text: "Hold ⇧ (shift) while pressing ↑ or ↓ to select multiple items"))
        selectCommands.add(Item(text: "Click and ⌘Click also work - best click next to the text, for example where some items show the arrow indicator on the right"))
        
        tour.append(selectCommands)
        
        // writing
        
        let moreCommands = Item(text: "Write Structured Texts")
        
        moreCommands.data.tag <- .orange
        
        let textIntroItem = Item(text: "Empty items correspond to paragraphs, while items with subitems correspond to headings...")
        textIntroItem.data.state <- .inProgress
        moreCommands.add(textIntroItem)
        moreCommands.add(Item(text: "Hit ↵ (return) to write a new item, then hit ↵ again to finish typing"))
        moreCommands.add(Item(text: "Press ⌘↵ to edit the first selected item"))
        moreCommands.add(Item(text: "Hit Space to add an item to the top"))
        moreCommands.add(Item(text: "Hit ⌫ (delete) to remove selected items"))
        let exportItem = Item(text: "Press ⌘E to export the FOCUSED (center) list and all its subitems to a plain TXT file. With paragraphs, headings, sub-headings etc.")
        exportItem.data.tag <- .blue
        moreCommands.add(exportItem)
        
        tour.append(moreCommands)
        
        // Manage Items

        let itemManagementCommands = Item(text: "Prioritize")
        
        itemManagementCommands.data.tag <- .yellow
        
        itemManagementCommands.add(Item(text: "Select a single item and hit ⌘↑ or ⌘↓ to move it up or down"))
        itemManagementCommands.add(Item(text: "Hit ⌘← to check off or uncheck an item"))
        itemManagementCommands.add(Item(text: "Hit ⌘→ to set an item in progress or to pause it"))
        
        tour.append(itemManagementCommands)
        
        // hierarchy
        
        let hierarchyCommands = Item(text: "Organize")
        
        hierarchyCommands.data.tag <- .green
        
        hierarchyCommands.add(Item(text: "Items that show an arrow on the right (like the \"Organize\" item) contain other items"))
        hierarchyCommands.add(Item(text: "You can move even into \"empty\" items and add new items into them"))
        hierarchyCommands.add(Item(text: "Select multiple items (⇧↑ and ⇧↓) and hit ↵ to group them and write their heading"))
        hierarchyCommands.add(Item(text: "You can move items between levels: Select them, cut via ⌘C, go to any other list via the arrow keys, and paste via ⌘V"))
        
        tour.append(hierarchyCommands)
        
        // tagging
        
        let taggingCommands = Item(text: "Press 1-6 or 0 to add or remove colors")
        
        taggingCommands.data.tag <- .blue
        
        tour.append(taggingCommands)
        
        // window
        
        let windowCommands = Item(text: "Font Size (Zoom), Dark Mode, Monotasking and Fullscreen")
        
        windowCommands.data.tag <- .purple
        
        windowCommands.add(Item(text: "Make the font (and everything) bigger or smaller via ⌘+ or ⌘-"))
        windowCommands.add(Item(text: "Switch between daylight mode and dark mode via ⌘D"))
        windowCommands.add(Item(text: "Switch between mono- and multitasking via ⌘M"))
        windowCommands.add(Item(text: "Toggle fullscreen via ⌘F"))
        windowCommands.add(Item(text: "Deactivate monotasking / fullscreen mode before activating the other mode"))
        
        tour.append(windowCommands)
        
        // contact
        
        let supportItem = Item(text: "support@flowlistapp.com")
        
        supportItem.add(Item(text: "What features do you miss? What do or don't you like about Flowlist?"))
        supportItem.add(Item(text: "The \"Help\" menu offers some web links that may be interesting"))
        supportItem.add(Item(text: "You may delete this welcome tour, the \"Help\" menu lets you create it again at any time"))
        
        tour.append(supportItem)
        
        return tour
    }
}
