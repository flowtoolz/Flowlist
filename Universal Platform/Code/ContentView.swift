import SwiftUI

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        RootView().colorScheme(.dark)
    }
}
#endif

struct RootView : View {
    var body: some View {
        ItemListView(root: TestItem.root)
    }
}

