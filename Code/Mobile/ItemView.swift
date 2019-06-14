import SwiftUI
import Combine
import SwiftObserver
import FlowlistKit

#if DEBUG
struct ItemView_Previews : PreviewProvider {
    static var previews: some View {
        ItemView(item: testItem)
            .previewLayout(.fixed(width: 300, height: 50))
    }
}
#endif

struct ItemView : View {
    @State var isChecked = false
    
    var body: some View {
        HStack {
            Button(action: { self.isChecked.toggle() } ) {
                Image(systemName: isChecked ? "checkmark.circle" : "circle")
                    .imageScale(.large)
            }
            NavigationButton(destination: ItemListView(item: item)) {
                Text(item.text)
            }
        }
    }
    
    var item: Item
}
