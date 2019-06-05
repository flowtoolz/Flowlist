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
        List {
            Section {
                Button(action: addItem) {
                    Text("Neues Item")
                }
            }
            Section {
                ForEach(root.children) { item in
                    NavigationButton(destination: ItemListView(root: item)) {
                        ItemView(item: item)
                    }
                }
                .onDelete(perform: removeItems)
            }
        }.navigationBarTitle(Text(root.text),
                             displayMode: .inline)
        .listStyle(.grouped)
    }
    
    func removeItems(at offsets: IndexSet) {
        Array(offsets).forEach {
            root.children.remove(at: $0)
        }
    }
    
    func addItem() {
        root.children.append(Item("Neues Item"))
    }
    
    @ObjectBinding var root: Item
}


