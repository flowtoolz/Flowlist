import SwiftObserver

extension Tree where Data == ItemData
{
    static var welcomeTour: [ItemDataTree]
    {
        var tour = [ItemDataTree]()
        
        tour.append(ItemDataTree("Welcome to Flowlist!"))
        tour[0].data.state <- .inProgress
        tour.append(ItemDataTree("Best select and edit with your keyboard"))
        tour[1].data.state <- .inProgress
        tour.append(ItemDataTree("The menus show all applicable commands in every situation"))
        
        // select
        
        let selectCommands = ItemDataTree("Move with the arrows: ↑ ↓ ← →")
        
        selectCommands.data.tag <- .red
        
        selectCommands.add(ItemDataTree("Hold ⇧ (shift) while pressing ↑ or ↓ to select multiple items"))
        selectCommands.add(ItemDataTree("Click and ⌘Click also work - best click next to the text, for example where some items show the arrow indicator on the right"))
        
        tour.append(selectCommands)
        
        // writing
        
        let moreCommands = ItemDataTree("Write Structured Texts")
        
        moreCommands.data.tag <- .orange
        
        let textIntroItem = ItemDataTree("Empty items correspond to paragraphs, while items with subitems correspond to headings...")
        textIntroItem.data.state <- .inProgress
        moreCommands.add(textIntroItem)
        moreCommands.add(ItemDataTree("Hit ↵ (return) to write a new item, then hit ↵ again to finish typing"))
        moreCommands.add(ItemDataTree("Press ⌘↵ to edit the first selected item"))
        moreCommands.add(ItemDataTree("Hit Space to add an item to the top"))
        moreCommands.add(ItemDataTree("Hit ⌫ (delete) to remove selected items"))
        let exportItem = ItemDataTree("Press ⌘E to export the FOCUSED (center) list and all its subitems to a plain TXT file. With paragraphs, headings, sub-headings etc.")
        exportItem.data.tag <- .blue
        moreCommands.add(exportItem)
        
        tour.append(moreCommands)
        
        // Manage Items

        let itemManagementCommands = ItemDataTree("Prioritize")
        
        itemManagementCommands.data.tag <- .yellow
        
        itemManagementCommands.add(ItemDataTree("Select a single item and hit ⌘↑ or ⌘↓ to move it up or down"))
        itemManagementCommands.add(ItemDataTree("Hit ⌘← to check off or uncheck an item"))
        itemManagementCommands.add(ItemDataTree("Hit ⌘→ to set an item in progress or to pause it"))
        
        tour.append(itemManagementCommands)
        
        // hierarchy
        
        let hierarchyCommands = ItemDataTree("Organize")
        
        hierarchyCommands.data.tag <- .green
        
        hierarchyCommands.add(ItemDataTree("Items that show an arrow on the right (like the \"Organize\" item) contain other items"))
        hierarchyCommands.add(ItemDataTree("You can move even into \"empty\" items and add new items into them"))
        hierarchyCommands.add(ItemDataTree("Select multiple items (⇧↑ and ⇧↓) and hit ↵ to group them and write their heading"))
        hierarchyCommands.add(ItemDataTree("You can move items between levels: Select them, cut via ⌘C, go to any other list via the arrow keys, and paste via ⌘V"))
        
        tour.append(hierarchyCommands)
        
        // tagging
        
        let taggingCommands = ItemDataTree("Press 1-6 or 0 to add or remove colors")
        
        taggingCommands.data.tag <- .blue
        
        tour.append(taggingCommands)
        
        // window
        
        let windowCommands = ItemDataTree("Font Size (Zoom), Dark Mode, Monotasking and Fullscreen")
        
        windowCommands.data.tag <- .purple
        
        windowCommands.add(ItemDataTree("Make the font (and everything) bigger or smaller via ⌘+ or ⌘-"))
        windowCommands.add(ItemDataTree("Switch between daylight mode and dark mode via ⌘D"))
        windowCommands.add(ItemDataTree("Switch between mono- and multitasking via ⌘M"))
        windowCommands.add(ItemDataTree("Toggle fullscreen via ⌘F"))
        windowCommands.add(ItemDataTree("Deactivate monotasking / fullscreen mode before activating the other mode"))
        
        tour.append(windowCommands)
        
        // contact
        
        let supportItem = ItemDataTree("support@flowlistapp.com")
        
        supportItem.add(ItemDataTree("What features do you miss? What do or don't you like about Flowlist?"))
        supportItem.add(ItemDataTree("The \"Help\" menu offers some web links that may be interesting"))
        supportItem.add(ItemDataTree("You may delete this welcome tour, the \"Help\" menu lets you create it again at any time"))
        
        tour.append(supportItem)
        
        return tour
    }
}
