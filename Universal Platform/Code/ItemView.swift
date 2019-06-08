import SwiftUI
import Combine
import SwiftObserver

#if DEBUG
struct ItemView_Previews : PreviewProvider {
    static var previews: some View {
        ItemView(item: testItem)
            .previewLayout(.fixed(width: 300, height: 50))
    }
}
#endif

struct ItemView : View {
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle")
                .imageScale(.large)
            Text(item.text)
            Spacer()
        }
    }
    
    var item: Item
}
