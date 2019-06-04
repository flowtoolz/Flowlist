import SwiftUI

#if DEBUG
struct ItemView_Previews : PreviewProvider {
    static var previews: some View {
        ItemView(item: TestItem.root)
    }
}
#endif

struct ItemView : View {
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle")
            Text(item.text)
        }
    }
    
    var item: TestItem
}

extension TestItem: Identifiable {
    var id: Int {
        ObjectIdentifier(self).hashValue
    }
}

class TestItem {
    static let root = TestItem("Home", [
        TestItem("Today"),
        TestItem("Lexoffice"),
        TestItem("Projects")
    ])
    
    private init(_ text: String,
                 _ children: [TestItem] = []) {
        self.text = text
        self.children = children
    }
    var text: String = "Test Text"
    var children = [TestItem]()
}
