import SwiftObserver
import SwiftyToolz

class ListItem: NewTree<ListItem.Data>
{
    init(with item: Task)
    {
        super.init()
        
        data = Data()
        
        data?.item = item
        
        for subItem in item.branches
        {
            append(ListItem(with: subItem))
        }
    }
    
    class Data
    {
        weak var item: Task?
    }
}
