import SwiftObserver

extension Array where Element == Item
{
    var allItems: [Item]
    {
        var result = [Item]()
        
        forEach { result.append(contentsOf: $0.allNodesRecursively) }
        
        return result
    }
}

extension Tree where Data == ItemData
{
    // selection
    
    var isSelected: Bool
    {
        get { return data.isSelected.value }
        set { data.isSelected <- newValue }
    }
    
    func deselectAll()
    {
        branches.forEach { $0.isSelected = false }
    }
    
    // focus
    
    var isFocused: Bool
    {
        get { return data.isFocused.value }
        set { data.isFocused <- newValue }
    }
    
    // property access
    
    var parent: ItemData.ID? { return root?.id }
    var position: Int { return indexInRoot ?? 0 }
    var id: ItemData.ID { return data.id }
    
    // text
    
    func edit() { data.requestTextInput() }
    var text: String? { return data.text.value }
}

typealias Item = Tree<ItemData>
