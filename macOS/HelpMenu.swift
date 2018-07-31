import AppKit

class HelpMenu: NSMenu
{
    // MARK: - Initialization
    
    init()
    {
        super.init(title: "Help")
        
        addItem(contactItem)
        
        addItem(NSMenuItem.separator())
        
        addItem(videoItem)
        addItem(keyCommandsItem)
        addItem(blogItem)
    }
    
    required init(coder decoder: NSCoder) { fatalError() }
    
    // MARK: - Action Availability
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
    {
        return true
    }
    
    // MARK: - Menu Items
    
    private lazy var videoItem = item("Watch Screencast Video",
                                      action: #selector(watchVideo),
                                      key: "")
    
    @objc private func watchVideo()
    {
        if let url = URL(string: "http://www.flowtoolz.com/flowlist#video")
        {
            NSWorkspace.shared.open(url)
        }
    }
    
    private lazy var keyCommandsItem = item("Learn Key Commands",
                                            action: #selector(learnKeyCommands),
                                            key: "")
    
    @objc private func learnKeyCommands()
    {
        if let url = URL(string: "http://www.flowtoolz.com/flowlist#key-commands")
        {
            NSWorkspace.shared.open(url)
        }
    }
    
    private lazy var blogItem = item("Learn About Flowlist",
                                     action: #selector(learnFlowlist),
                                     key: "")
    
    @objc private func learnFlowlist()
    {
        if let url = URL(string: "http://www.flowtoolz.com/2018/07/13/how-a-minimalist-productivity-app-changed-my-life.html")
        {
            NSWorkspace.shared.open(url)
        }
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
}
