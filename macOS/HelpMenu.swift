import AppKit

class HelpMenu: NSMenu
{
    // MARK: - Initialization
    
    init()
    {
        super.init(title: "Help")
        
        addItem(videoItem)
        addItem(keyCommandsItem)
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
                                            action: #selector(learKeyCommands),
                                            key: "")
    
    @objc private func learKeyCommands()
    {
        if let url = URL(string: "http://www.flowtoolz.com/flowlist#key-commands")
        {
            NSWorkspace.shared.open(url)
        }
    }
}
