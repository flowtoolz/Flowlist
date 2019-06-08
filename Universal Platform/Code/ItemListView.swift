import SwiftUI
import Combine
 
#if DEBUG
struct ItemListView_Previews : PreviewProvider {
    static var previews: some View {
        ItemListView(root: testItem).colorScheme(.dark)
    }
}
#endif
 
struct ItemListView : View {
    
    var body: some View {
        List {
            Section {
                Button(action: addItem) {
                    Text("Neues Item")
                }
            }
            Section {
                ForEach(root.children) { child in
                    NavigationButton(destination: ItemListView(root: child)) {
                        ItemView(item: child)
                    }
                }
                .onDelete(perform: removeItems)
                .onMove(perform: moveItems)
            }
        }
        .navigationBarTitle(Text(root.text), displayMode: .inline)
        .navigationBarItems(trailing: EditButton())
        .listStyle(.grouped)
    }
    
    func removeItems(at offsets: IndexSet) {
        Array(offsets).forEach {
            root.children.remove(at: $0)
        }
    }
    
    func moveItems(from source: IndexSet, to destination: Int) {
        root.children.move(from: source, to: destination)
    }
    
    func addItem() {
        root.children.append(Item("Neues Item"))
    }
    
    @ObjectBinding var root: Item
}

extension Array {
    mutating func move(from source: IndexSet, to destination: Int) {
        Array<Int>(source).forEach {
            insert(remove(at: $0), at: destination)
        }
    }
}

// TODO: apparently classes don't need to conform to Identifiable in order to be displayed in a list... where is that documented and how is it technically achieved? how do classes auto-comply to identifiable?
extension Item: BindableObject {}

