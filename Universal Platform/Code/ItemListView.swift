import SwiftUI

#if DEBUG
struct ItemListView_Previews : PreviewProvider {
    static var previews: some View {
        ItemListView(root: testItem).colorScheme(.dark)
    }
}
#endif

let testItem = Item("Home", [
    Item("Today", [Item("Learn SwiftUI")]),
    Item("Lexoffice"),
    Item("Projects")
    ])

struct ItemListView : View {
    var body: some View {
        List(root.children) { item in
            NavigationButton(destination: ItemListView(root: item)) {
                ItemView(item: item)
            }
        }.navigationBarTitle(Text(root.text),
                             displayMode: .inline)
    }
    
    var root: Item
}


