import AppKit

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
        if let listView = listView
        {
            listView.translatesAutoresizingMaskIntoConstraints = true
            view = listView
        }
        else
        {
            view = NSView()
        }
    }
    
    private weak var listView: ListView?
}
