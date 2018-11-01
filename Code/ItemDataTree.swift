import SwiftObserver

extension Tree where Data == ItemData
{
    func edit() { data.edit() }
    
    func deselectAll()
    {
        for item in branches
        {
            item.isSelected = false
        }
    }
    
    var text: String? { return data.text.value }
    
    var isSelected: Bool
    {
        get { return data.isSelected.value ?? false }
        set { data.isSelected <- newValue }
    }
    
    var isFocused: Bool
    {
        get { return data.isFocused.value ?? false }
        set { data.isFocused <- newValue }
    }
}

typealias ItemDataTree = Tree<ItemData>
