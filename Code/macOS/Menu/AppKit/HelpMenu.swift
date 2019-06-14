import AppKit
import UIToolz

class HelpMenu: NSMenu, NSMenuItemValidation
{
    // MARK: - Initialization
    
    init()
    {
        super.init(title: "Help")
        
        addItem(contactItem)
        
        addItem(NSMenuItem.separator())
        
        addItem(tourItem)
        addItem(videoItem)
        addItem(keyCommandsItem)
        
        addItem(NSMenuItem.separator())
        
        addItem(voteItem)
    }
    
    required init(coder decoder: NSCoder) { fatalError() }
    
    // MARK: - Action Availability
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
    {
        let mainWindowIsKey = NSApp.mainWindow?.isKeyWindow ?? false
        
        switch menuItem
        {
        case tourItem: return !reachedItemNumberLimit && mainWindowIsKey
        default: return true
        }
    }
    
    // MARK: - Menu Items
    
    private let videoItem = MenuItem("Watch Screencast Video (Web)", key: "")
    {
        if let url = URL(string: "https://www.flowtoolz.com/flowlist?utm_source=Flowlist&utm_medium=referral&utm_content=WatchScreencastVideo#video")
        {
            NSWorkspace.shared.open(url)
        }
    }
    
    private let keyCommandsItem = MenuItem("Learn Key Commands (Web)", key: "")
    {
        if let url = URL(string: "https://www.flowtoolz.com/flowlist?utm_source=Flowlist&utm_medium=referral&utm_content=LearnKeyCommands#key-commands")
        {
            NSWorkspace.shared.open(url)
        }
    }
    
    private lazy var tourItem = MenuItem("Paste Welcome Tour",
                                         key: "",
                                         validator: self)
    {
        let tour = Item(text: "Welcome Tour")
        tour.insert(Item.welcomeTour, at: 0)
        browser.focusedList.paste([tour])
    }
    
    private let contactItem = MenuItem("Contact Me: hello@flowlistapp.com",
                                       key: "")
    {
        if let url = URL(string: "mailto:hello%40flowlistapp.com?SUBJECT=Flowlist")
        {
            NSWorkspace.shared.open(url)
        }
    }
    
    private let voteItem = MenuItem("Vote on New Features (Web)", key: "")
    {
        if let url = URL(string: "https://flowtoolz.typeform.com/to/R5lp8b")
        {
            NSWorkspace.shared.open(url)
        }
    }
}
