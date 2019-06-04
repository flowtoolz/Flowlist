import SwiftUI

#if DEBUG
struct ListView_Previews : PreviewProvider {
    static var previews: some View {
        ItemListView(root: TestItem.root).colorScheme(.dark)
    }
}
#endif

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
    
    var root: TestItem
}


