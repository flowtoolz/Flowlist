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
        get { data.isSelected.value }
        set { data.isSelected <- newValue }
    }
    
    func deselectAll()
    {
        children.forEach { $0.isSelected = false }
    }
    
    // focus
    
    var isFocused: Bool
    {
        get { data.isFocused.value }
        set { data.isFocused <- newValue }
    }
    
    // property access
    
    var parentID: ItemData.ID? { parent?.id }
    var position: Int { indexInParent ?? 0 }
    var id: ItemData.ID { data.id }
    
    // text
    
    func edit() { data.requestTextInput() }
    var text: String? { data.text.value }
}

typealias Item = Tree<ItemData>
