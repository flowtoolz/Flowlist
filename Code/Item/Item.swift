import SwiftObserver

extension Array where Element == Item
{
    var allItems: [Item]
    {
        var result = [Item]()
        
        forEach { result.append(contentsOf: $0.array) }
        
        return result
    }
}

extension Tree where Data == ItemData
{
    // selection
    
    var isSelected: Bool
    {
        get { return data.isSelected.value ?? false }
        set { data.isSelected <- newValue }
    }
    
    func deselectAll()
    {
        branches.forEach { $0.isSelected = false }
    }
    
    // text
    
    func edit() { data.requestTextInput() }
    
    var text: String? { return data.text.value }
    
    // focus
    
    var isFocused: Bool
    {
        get { return data.isFocused.value ?? false }
        set { data.isFocused <- newValue }
    }
}

typealias Item = Tree<ItemData>
