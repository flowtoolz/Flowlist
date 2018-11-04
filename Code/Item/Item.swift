import SwiftObserver

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
        for item in branches
        {
            item.isSelected = false
        }
    }
    
    // text
    
    func edit() { data.edit() }
    
    var text: String? { return data.text.value }
    
    // focus
    
    var isFocused: Bool
    {
        get { return data.isFocused.value ?? false }
        set { data.isFocused <- newValue }
    }
}

typealias Item = Tree<ItemData>
