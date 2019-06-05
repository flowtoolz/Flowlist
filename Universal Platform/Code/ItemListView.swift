import SwiftUI

#if DEBUG
struct ItemListView_Previews : PreviewProvider {
    static var previews: some View {
        ItemListView(root: testItem).colorScheme(.dark)
    }
}
#endif

let testItem = Item("Home", [
    Item("Today"),
    Item("Lexoffice"),
    Item("Projects")
    ])

struct ItemListView : View {
    var body: some View {
        NavigationView {
            List(root.children) { item in
                NavigationButton(destination: ItemListView(root: item)) {
                    ItemView(item: item)
                }
            }.navigationBarTitle(Text(root.text))
        }
    }
    
    var root: Item
}


