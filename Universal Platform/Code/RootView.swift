import SwiftUI

#if DEBUG
struct RootView_Previews : PreviewProvider {
    static var previews: some View {
        RootView().colorScheme(.dark)
    }
}
#endif

struct RootView : View {
    var body: some View {
        NavigationView {
            ItemListView(item: testItem)
        }
    }
}
