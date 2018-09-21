import SwiftObserver

extension Task
{
    static var welcomeTour: [Task]
    {
        var tour = [Task]()
        
        tour.append(Task("Welcome to Flowlist!"))
        tour.append(Task("Best select and edit with your keyboard"))
        tour.append(Task("The menus show all applicable commands in every situation"))
        
        // select
        
        let selectCommands = Task("Move with the arrows: ↑ ↓ ← →")
        
        selectCommands.tag <- .red
        
        selectCommands.add(Task("Hold ⇧ (shift) while pressing ↑ or ↓ to select multiple items"))
        selectCommands.add(Task("Click and ⌘Click also work - best click next to the text, for example where some items show the arrow indicator on the right"))
        
        tour.append(selectCommands)
        
        // writing
        
        let moreCommands = Task("Write")
        
        moreCommands.tag <- .orange
        
        moreCommands.add(Task("Hit ↵ (return) to write a new item, then hit ↵ again to finish typing"))
        moreCommands.add(Task("Hit ⌘↵ to edit the first selected item"))
        moreCommands.add(Task("Hit Space to add an item to the top"))
        moreCommands.add(Task("Hit ⌫ (delete) to remove the selection"))
        
        tour.append(moreCommands)
        
        // Manage Tasks

        let taskManagementCommands = Task("Prioritize")
        
        taskManagementCommands.tag <- .yellow
        
        taskManagementCommands.add(Task("Select a single item and hit ⌘↑ or ⌘↓ to move it up or down"))
        taskManagementCommands.add(Task("Hit ⌘← to check off or uncheck an item"))
        taskManagementCommands.add(Task("Hit ⌘→ to set an item in progress or to pause it"))
        
        tour.append(taskManagementCommands)
        
        // hierarchy
        
        let hierarchyCommands = Task("Organize")
        
        hierarchyCommands.tag <- .green
        
        hierarchyCommands.add(Task("Items that show an arrow on the right (like the \"Organize\" item) contain other items"))
        hierarchyCommands.add(Task("You can move even into \"empty\" items and add new items into them"))
        hierarchyCommands.add(Task("Select multiple items (⇧↑ and ⇧↓) and hit ↵ to group them and write their heading"))
        hierarchyCommands.add(Task("You can move items between levels: Select them, cut via ⌘C, go to any other list via the arrow keys, and paste via ⌘V"))
        
        tour.append(hierarchyCommands)
        
        // tagging
        
        let taggingCommands = Task("Press 1-6 or 0 to add or remove colors")
        
        taggingCommands.tag <- .blue
        
        tour.append(taggingCommands)
        
        // window
        
        let windowCommands = Task("Font Size (Zoom), Dark Mode, Monotasking and Fullscreen")
        
        windowCommands.tag <- .purple
        
        windowCommands.add(Task("Make the font (and everything) bigger or smaller via ⌘+ or ⌘-"))
        windowCommands.add(Task("Switch between daylight mode and dark mode via ⌘D"))
        windowCommands.add(Task("Switch between mono- and multitasking via ⌘M"))
        windowCommands.add(Task("Toggle fullscreen via ⌘F"))
        windowCommands.add(Task("Deactivate monotasking / fullscreen mode before activating the other mode"))
        
        tour.append(windowCommands)
        
        // contact
        
        let supportItem = Task("support@flowlistapp.com")
        
        supportItem.add(Task("What features do you miss? What do or don't you like about Flowlist?"))
        supportItem.add(Task("The \"Help\" menu offers some web links that may be interesting"))
        supportItem.add(Task("You may delete this welcome tour, the \"Help\" menu lets you create it again at any time"))
        
        tour.append(supportItem)
        
        return tour
    }
}
