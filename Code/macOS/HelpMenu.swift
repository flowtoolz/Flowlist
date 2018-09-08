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
        case tourItem: return !reachedTaskNumberLimit
        default: return true
        }
    }
    
    // MARK: - Menu Items
    
    private lazy var videoItem = item("Watch Screencast Video",
                                      action: #selector(watchVideo),
                                      key: "")
    
    @objc private func watchVideo()
    {
        if let url = URL(string: "http://www.flowtoolz.com/flowlist?utm_source=Flowlist&utm_medium=referral&utm_content=WatchScreencastVideo#video")
        {
            NSWorkspace.shared.open(url)
        }
    }
    
    private lazy var keyCommandsItem = item("Learn Key Commands",
                                            action: #selector(learnKeyCommands),
                                            key: "")
    
    @objc private func learnKeyCommands()
    {
        if let url = URL(string: "http://www.flowtoolz.com/flowlist?utm_source=Flowlist&utm_medium=referral&utm_content=LearnKeyCommands#key-commands")
        {
            NSWorkspace.shared.open(url)
        }
    }
    
    private lazy var blogItem = item("Learn About Flowlist",
                                     action: #selector(learnFlowlist),
                                     key: "")
    
    @objc private func learnFlowlist()
    {
        if let url = URL(string: "http://www.flowtoolz.com/2018/07/13/how-a-minimalist-productivity-app-changed-my-life.html?utm_source=Flowlist&utm_medium=referral&utm_content=LearnFlowlist")
        {
            NSWorkspace.shared.open(url)
        }
    }
    
    private lazy var tourItem = item("Paste Welcome Tour",
                                     action: #selector(pasteTour),
                                     key: "")
    
    @objc private func pasteTour()
    {
        let tour = Task("Welcome Tour")
        tour.insert(Task.welcomeTour, at: 0)
        Browser.active?.focusedList.paste([tour])
    }
    
    private lazy var contactItem = item("Contact Me: support@flowlistapp.com",
                                        action: #selector(contactMe),
                                        key: "")
    
    @objc private func contactMe()
    {
        if let url = URL(string: "mailto:support%40flowlistapp.com?SUBJECT=Flowlist")
        {
            NSWorkspace.shared.open(url)
        }
    }
    
    private lazy var voteItem = item("Vote on the Next Features",
                                     action: #selector(vote),
                                     key: "")
    
    @objc private func vote()
    {
        if let url = URL(string: "https://flowtoolz.typeform.com/to/R5lp8b")
        {
            NSWorkspace.shared.open(url)
        }
    }
}
