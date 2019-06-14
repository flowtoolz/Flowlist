import SwiftObserver
import SwiftyToolz

extension ItemData: Copyable
{
    convenience init(with original: ItemData)
    {
        self.init()
        
        text <- original.text.value
        state <- original.state.value
        tag <- original.tag.value
    }
}
