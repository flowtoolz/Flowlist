import AppKit
import UIToolz

class ViewController: NSViewController
{
    override func loadView()
    {
        view = LayerBackedView()
        
        browserView.autoPinEdgesToSuperviewEdges()
    }

    private lazy var browserView: BrowserView =
    {
        let bv = BrowserView.newAutoLayout()
        view.addSubview(bv)
        
        return bv
    }()
}
