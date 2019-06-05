import Combine

class Item: Publisher {
    func receive<S>(subscriber: S) where S : Subscriber, Error == S.Failure, String == S.Input {
        
    }
    
    typealias Failure = Error
    
    typealias Output = String
    
    init(_ text: String, _ children: [Item] = []) {
        self.text = text
        self.children = children
    }
    
    var text: String = "Test Text"
    var children = [Item]()
}

