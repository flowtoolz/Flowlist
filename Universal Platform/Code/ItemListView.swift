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

/*
 Item is Identifiable since classes automatically conform to Identifiable, via this in the SwiftUI API:
 
 extension Identifiable where Self : AnyObject {
     public var id: ObjectIdentifier { get }
 }
 
 BindableObject conforms to Identifiable. And the above extension of Identifiable is applied to Item before the conformance of Item to that protocol even gets checked.
 
 Just by adopting/knowing a protocol extension you can gain conformance to that same protocol 🤯
*/
extension Item: BindableObject {}

