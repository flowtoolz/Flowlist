extension Item: Encodable
{
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: ItemCodingKey.self)
        
        container.set(data?.id, for: .id)
        container.set(text, for: .text)
        container.set(data?.state.value?.rawValue, for: .state)
        container.set(data?.tag.value?.rawValue, for: .tag)
        
        if !isLeaf
        {
            let subitems: [Item] = branches.map { Item(from: $0) }
            
            container.set(subitems, for: .branches)
        }
    }
    
    convenience init(from itemDataTree: ItemDataTree)
    {
        self.init(data: itemDataTree.data,
                  root: itemDataTree.root,
                  numberOfLeafs: itemDataTree.numberOfLeafs)
        
        reset(branches: itemDataTree.branches)
    }
}
