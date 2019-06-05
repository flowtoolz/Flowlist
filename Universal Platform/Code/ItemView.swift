import SwiftUI

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
        HStack() {
            Image(systemName: "checkmark.circle").imageScale(.large)
            Text(item.text)
            Spacer()
        }.frame(minWidth: 0, // makes the view "stretch out" like a spacer
                maxWidth: .infinity,
                minHeight: 0,
                maxHeight: .infinity)
    }
    
    var item: Item
}

extension Item: Identifiable {
    var id: Int {
        ObjectIdentifier(self).hashValue
    }
}
