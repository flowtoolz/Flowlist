import SwiftObserver

public let testItem = Item("Home", [
    Item("Today", [Item("Learn SwiftUI")]),
    Item("Lexoffice"),
    Item("We need one item with a really long text to see how the app handles multi line items, in particular how they effect layout."),
    Item("Projects")
    ])

public class Item: CustomObservable {
    
    public init(_ text: String, _ children: [Item] = []) {
        self.text = text
        self.children = children
    }
    
    public var text: String { didSet { send() } }
    public var children: [Item] { didSet { send() } }
    
    public let messenger = Messenger<Message>()
    public typealias Message = String?
}

