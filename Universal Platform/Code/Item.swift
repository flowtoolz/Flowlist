import Combine

let testItem = Item("Home", [
    Item("Today", [Item("Learn SwiftUI")]),
    Item("Lexoffice"),
    Item("We need one item with a really long text to see how the app handles multi line items, in particular how they effect layout."),
    Item("Projects")
    ])

class Item {
    
    init(_ text: String, _ children: [Item] = []) {
        self.text = text
        self.children = children
    }
    
    var text: String
    var children: [Item] {
        didSet {
            didChange.send(())
        }
    }
    
    // TODO: proof concept: make model class independent of Combine and use SwiftObserver instead. Let the View then care about having some view specific and SwiftUI-specific bindings
    let didChange = PassthroughSubject<Void, Never>()
}

