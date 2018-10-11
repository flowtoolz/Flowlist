import SwiftObserver

extension Tree where Data == ItemData
{
    static var welcomeTour: [Item]
    {
        var tour = [Item]()
        
        tour.append(Item("Welcome to Flowlist!"))
        tour[0].data?.state <- .inProgress
        tour.append(Item("Best select and edit with your keyboard"))
        tour[1].data?.state <- .inProgress
        tour.append(Item("The menus show all applicable commands in every situation"))
        
        // select
        
        let selectCommands = Item("Move with the arrows: ↑ ↓ ← →")
        
        selectCommands.data?.tag <- .red
        
        selectCommands.add(Item("Hold ⇧ (shift) while pressing ↑ or ↓ to select multiple items"))
        selectCommands.add(Item("Click and ⌘Click also work - best click next to the text, for example where some items show the arrow indicator on the right"))
        
        tour.append(selectCommands)
        
        // writing
        
        let moreCommands = Item("Write")
        
        moreCommands.data?.tag <- .orange
        
        moreCommands.add(Item("Hit ↵ (return) to write a new item, then hit ↵ again to finish typing"))
        moreCommands.add(Item("Hit ⌘↵ to edit the first selected item"))
        moreCommands.add(Item("Hit Space to add an item to the top"))
        moreCommands.add(Item("Hit ⌫ (delete) to remove the selection"))
        
        tour.append(moreCommands)
        
        // Manage Items

        let itemManagementCommands = Item("Prioritize")
        
        itemManagementCommands.data?.tag <- .yellow
        
        itemManagementCommands.add(Item("Select a single item and hit ⌘↑ or ⌘↓ to move it up or down"))
        itemManagementCommands.add(Item("Hit ⌘← to check off or uncheck an item"))
        itemManagementCommands.add(Item("Hit ⌘→ to set an item in progress or to pause it"))
        
        tour.append(itemManagementCommands)
        
        // hierarchy
        
        let hierarchyCommands = Item("Organize")
        
        hierarchyCommands.data?.tag <- .green
        
        hierarchyCommands.add(Item("Items that show an arrow on the right (like the \"Organize\" item) contain other items"))
        hierarchyCommands.add(Item("You can move even into \"empty\" items and add new items into them"))
        hierarchyCommands.add(Item("Select multiple items (⇧↑ and ⇧↓) and hit ↵ to group them and write their heading"))
        hierarchyCommands.add(Item("You can move items between levels: Select them, cut via ⌘C, go to any other list via the arrow keys, and paste via ⌘V"))
        
        tour.append(hierarchyCommands)
        
        // tagging
        
        let taggingCommands = Item("Press 1-6 or 0 to add or remove colors")
        
        taggingCommands.data?.tag <- .blue
        
        tour.append(taggingCommands)
        
        // window
        
        let windowCommands = Item("Font Size (Zoom), Dark Mode, Monotasking and Fullscreen")
        
        windowCommands.data?.tag <- .purple
        
        windowCommands.add(Item("Make the font (and everything) bigger or smaller via ⌘+ or ⌘-"))
        windowCommands.add(Item("Switch between daylight mode and dark mode via ⌘D"))
        windowCommands.add(Item("Switch between mono- and multitasking via ⌘M"))
        windowCommands.add(Item("Toggle fullscreen via ⌘F"))
        windowCommands.add(Item("Deactivate monotasking / fullscreen mode before activating the other mode"))
        
        tour.append(windowCommands)
        
        // contact
        
        let supportItem = Item("support@flowlistapp.com")
        
        supportItem.add(Item("What features do you miss? What do or don't you like about Flowlist?"))
        supportItem.add(Item("The \"Help\" menu offers some web links that may be interesting"))
        supportItem.add(Item("You may delete this welcome tour, the \"Help\" menu lets you create it again at any time"))
        
        tour.append(supportItem)
        
        return tour
    }
}
