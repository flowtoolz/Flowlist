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
        guard let listView = listView else
        {
            view = NSView()
            return
        }
        
        listView.translatesAutoresizingMaskIntoConstraints = true
        view = listView
    }
    
    private weak var listView: ListView?
}
