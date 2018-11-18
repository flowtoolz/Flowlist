import FoundationToolz
import SwiftObserver
import SwiftyToolz

class ItemJSONFile: ItemFile
{
    static let shared = ItemJSONFile()
    
    private init() {}
    
    func loadItem() -> Item?
    {
        guard let fileUrl = url else { return nil }
        
        let manager = FileManager.default
        
        guard manager.fileExists(atPath: fileUrl.path) else
        {
            let item = Item(text: NSFullUserName())
            
            save(item)
            
            return item
        }
        
        guard let item = DecodableItem(fileURL: fileUrl) else
        {
            let title = "Couldn't Read From \"\(filename)\""
            
            let message = "Please ensure your file at \(fileUrl.path) is formatted correctly. Then restart Flowlist.\n\nBe careful to retain the JSON format when editing the file outside of Flowlist."
            
            log(error: message, title: title, forUser: true)
            
            return nil
        }
        
        return item
    }
    
    func save(_ item: Item)
    {
        guard let file = url, let _ = item.save(to: file) else
        {
            let fileString = self.url?.absoluteString ?? "file"
            log(error: "Could not save items to " + fileString)
            return
        }
    }
    
    // MARK: - File URL
    
    var url: URL?
    {
        return URL.documentDirectory?.appendingPathComponent(filename)
    }
    
    private var filename: String
    {
        #if DEBUG
        return "flowlist_debug.json"
        #else
        return "flowlist.json"
        #endif
    }
}
