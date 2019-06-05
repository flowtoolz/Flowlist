import Combine
import SwiftUI

class Item : BindableObject {
    
    init(_ text: String, _ children: [Item] = []) {
        self.text = text
        self.children = children
    }
    
    var text: String
    var children: [Item] {
        didSet {
            self.didChange.send(())
        }
    }
    
    var didChange = PassthroughSubject<Void, Never>()
}

