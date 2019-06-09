import SwiftUI
import SwiftObserver
import Combine
 
#if DEBUG
struct ItemListView_Previews : PreviewProvider {
    static var previews: some View {
        ItemListView(item: testItem).colorScheme(.dark)
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
                ForEach(source.children) { child in
                    NavigationButton(destination: ItemListView(item: child)) {
                        ItemView(item: child)
                    }
                }
                .onDelete(perform: removeItems)
                .onMove(perform: moveItems)
            }
        }
        .navigationBarTitle(Text(source.item?.text ?? ""), displayMode: .inline)
        .navigationBarItems(trailing: EditButton())
        .listStyle(.grouped)
    }
    
    func removeItems(at offsets: IndexSet) {
        Array(offsets).forEach {
            source.children.remove(at: $0)
        }
    }
    
    func moveItems(from sourceIndexes: IndexSet, to destination: Int) {
        source.children.move(from: sourceIndexes, to: destination)
    }
    
    func addItem() {
        source.children.append(Item("Neues Item"))
    }
    
    init(item: Item) {
        source = Source(item: item)
    }
    
    @ObjectBinding private var source: Source
}

extension Array {
    mutating func move(from source: IndexSet,
                       to destination: Int) {
        Array<Int>(source).forEach {
            insert(remove(at: $0), at: destination)
        }
    }
}

/*
 Item is Identifiable since classes that declare conformance to Identifiable get the required implementation via this in the SwiftUI API:
 
 extension Identifiable where Self : AnyObject {
     public var id: ObjectIdentifier { get }
 }
 
 The above extension of Identifiable is applied to class before the conformance of the class to that protocol even gets checked. Just by adopting/knowing a protocol extension you can gain conformance to that same protocol 🤯
*/
extension Item: Identifiable {}

// we have this extra layer so our model class does not have to depend SwiftUI and so the view does not have to hold the model strongly
private class Source: Observer, BindableObject {
    
    // MARK: - Notify Subscribing View of Item Updates
    
    init(item: Item) {
        self.item = item
        observe(item) { [weak self] _ in
            self?.didChange.send(())
        }
    }
    
    deinit { stopObserving() }
    
    let didChange = PassthroughSubject<Void, Never>()
    
    // MARK: - Provide Access to Item
    
    var children: [Item] {
        set { item?.children = newValue }
        get { item?.children ?? [] }
    }
    
    weak var item: Item?
}
