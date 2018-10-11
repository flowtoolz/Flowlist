import AppKit

class HelpMenu: NSMenu
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
        addItem(blogItem)
        
        addItem(NSMenuItem.separator())
        
        addItem(voteItem)
    }
    
    required init(coder decoder: NSCoder) { fatalError() }
    
    // MARK: - Action Availability
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
    {
        switch menuItem
        {
        case tourItem: return !reachedItemNumberLimit
        default: return true
        }
    }
    
    // MARK: - Menu Items
    
    private let videoItem = MenuItem("Watch Screencast Video", key: "")
    {
        if let url = URL(string: "http://www.flowtoolz.com/flowlist?utm_source=Flowlist&utm_medium=referral&utm_content=WatchScreencastVideo#video")
        {
            NSWorkspace.shared.open(url)
        }
    }
    
    private let keyCommandsItem = MenuItem("Learn Key Commands", key: "")
    {
        if let url = URL(string: "http://www.flowtoolz.com/flowlist?utm_source=Flowlist&utm_medium=referral&utm_content=LearnKeyCommands#key-commands")
        {
            NSWorkspace.shared.open(url)
        }
    }
    
    private let blogItem = MenuItem("Learn About Flowlist", key: "")
    {
        if let url = URL(string: "http://www.flowtoolz.com/2018/07/13/how-a-minimalist-productivity-app-changed-my-life.html?utm_source=Flowlist&utm_medium=referral&utm_content=LearnFlowlist")
        {
            NSWorkspace.shared.open(url)
        }
    }
    
    private lazy var tourItem = MenuItem("Paste Welcome Tour",
                                         key: "",
                                         validator: self)
    {
        let tour = Item("Welcome Tour")
        tour.insert(Item.welcomeTour, at: 0)
        browser.focusedList.paste([tour])
    }
    
    private let contactItem = MenuItem("Contact Me: support@flowlistapp.com",
                                       key: "")
    {
        if let url = URL(string: "mailto:support%40flowlistapp.com?SUBJECT=Flowlist")
        {
            NSWorkspace.shared.open(url)
        }
    }
    
    private let voteItem = MenuItem("Vote on the Next Features", key: "")
    {
        if let url = URL(string: "https://flowtoolz.typeform.com/to/R5lp8b")
        {
            NSWorkspace.shared.open(url)
        }
    }
}
