import AppKit
import UIToolz

class ViewController: NSViewController
{
    // MARK: - View Life Cycle
    
    override func loadView() { view = LayerBackedView() }
    
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
