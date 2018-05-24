import AppKit

class Controller: NSViewController
{
    // MARK: - Life Cycle
    
    override func loadView()
    {
        view = NSView()
        view.wantsLayer = true
    }
    
    // MARK: - View Delegate
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        constrainBrowserView()
    }
    
    override func viewDidAppear()
    {
        browserView.configureListViews()
    }
    
    // MARK: - Browser View

    private func constrainBrowserView()
    {
        browserView.autoPinEdgesToSuperviewEdges()
    }
    
    private lazy var browserView: BrowserView =
    {
        let bv = BrowserView.newAutoLayout()
        view.addSubview(bv)
        
        return bv
    }()
}
