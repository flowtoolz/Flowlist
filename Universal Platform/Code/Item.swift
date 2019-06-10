import SwiftObserver

let testItem = Item("Home", [
    Item("Today", [Item("Learn SwiftUI")]),
    Item("Lexoffice"),
    Item("We need one item with a really long text to see how the app handles multi line items, in particular how they effect layout."),
    Item("Projects")
    ])

class Item: CustomObservable {
    
    init(_ text: String, _ children: [Item] = []) {
        self.text = text
        self.children = children
    }
    
    var text: String
    var children: [Item] { didSet { send() } }
    
    let messenger = Messenger<Message>()
    typealias Message = String?
}

