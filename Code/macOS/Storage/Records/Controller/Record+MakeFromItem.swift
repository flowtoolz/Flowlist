import SwiftObserver

extension Record
{
    init(item: Item)
    {
        let data = item.data
        
        self.init(id: data.id,
                  text: data.text.value,
                  state: data.state.value,
                  tag: data.tag.value,
                  parent: item.parent,
                  position: item.position)
    }
}
