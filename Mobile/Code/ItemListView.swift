import SwiftUI
import Combine
import SwiftObserver
import FlowlistKit
 
#if DEBUG
struct ItemListView_Previews : PreviewProvider {
    static var previews: some View {
        ItemListView(item: testItem).colorScheme(.dark)
    }
}
#endif
 
struct ItemListView : View {
    
    var body: some View {
        VStack {
            List {
                Section {
                    ForEach(source.children) { child in
                        ItemView(item: child)
                    }
                    .onDelete(perform: removeItems)
                    .onMove(perform: moveItems)
                }
            }
                .navigationBarTitle(Text(source.text),
                                    displayMode: .inline)
                .navigationBarItems(trailing: EditButton())
                .listStyle(.grouped)
            
            VStack {
                HStack {
                    Image(systemName: "pencil.circle")
                        .imageScale(.large)
                    TextField($source.text) {
                        UIApplication.shared.keyWindow?.endEditing(true)
                    }
                }.padding()
                HStack {
                    Button(action: addItem) {
                        Image(systemName: "checkmark.circle")
                            .imageScale(.large)
                    }
                    Text("Check Off")
                    Spacer()
                    Button(action: addItem) {
                        Image(systemName: "plus.circle")
                            .imageScale(.large)
                    }
                    Text("Add")
                }.padding()
            }
        }
    }
    
    func removeItems(at offsets: IndexSet) {
        source.children.remove(from: offsets)
    }
    
    func moveItems(from offsets: IndexSet, to destination: Int) {
        source.children.move(from: offsets, to: destination)
    }
    
    func addItem() {
        source.children.append(Item("New Item"))
    }
    
    init(item: Item) {
        source = Source(item: item)
    }
    
    @ObjectBinding private var source: Source
}

/*
 Item is Identifiable since classes that declare conformance to Identifiable get the required implementation via this in the SwiftUI API:
 
 extension Identifiable where Self : AnyObject {
     public var id: ObjectIdentifier { get }
 }
 
 The above extension of Identifiable is applied to class before the conformance of the class to that protocol even gets checked. Just by adopting/knowing a protocol extension you can gain conformance to that same protocol 🤯
*/
extension Item: Identifiable {}

// we have this extra layer so our model class does not have to depend on SwiftUI and so the view does not have to hold the model strongly
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
    
    var text: String {
        set { item?.text = newValue }
        get { item?.text ?? "" }
    }
    
    var children: [Item] {
        set { item?.children = newValue }
        get { item?.children ?? [] }
    }
    
    weak var item: Item?
}
