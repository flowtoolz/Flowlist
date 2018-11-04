import SwiftObserver
import SwiftyToolz

extension ItemData: Copyable
{
    convenience init(with original: ItemData)
    {
        self.init()
        
        text = Var(original.text.value)
        state = Var(original.state.value)
        tag = Var(original.tag.value)
    }
}
