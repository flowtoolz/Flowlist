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
        
        // Todo List Example by Chris Eidhof
        // https://gist.github.com/chriseidhof/603354ee7d52df77f7aec52ead538f94
        // ContentView(store: SimpleStore(MyState()).bindable)
    }
}
