import SwiftObserver
import SwiftyToolz

extension ItemData: Copyable
{
    convenience init(with original: ItemData)
    {
        self.init()
        
        title = Var(original.title.value)
        state = Var(original.state.value)
        tag = Var(original.tag.value)
    }
}
