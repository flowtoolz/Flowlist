import AppKit
import UIToolz

class ViewController: NSViewController
{
    override func loadView()
    {
        view = LayerBackedView()
        
        let browserView = view.addForAutoLayout(BrowserView())
        browserView.autoPinEdgesToSuperviewEdges()
    }
}
