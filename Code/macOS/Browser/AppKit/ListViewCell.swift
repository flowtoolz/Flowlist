import AppKit
import GetLaid

class ListViewCell: NSCollectionViewItem
{
    init(listView: ListView?)
    {
        self.listView = listView
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func loadView()
    {
        view = NSView()
        
        if let listView = listView
        {
            view.addForAutoLayout(listView).constrainToParent()
        }
    }
    
    private weak var listView: ListView?
}
