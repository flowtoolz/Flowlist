import FoundationToolz
import SwiftObserver
import SwiftyToolz

class ItemJSONFile: ItemFile
{
    init(url: URL = ItemJSONFile.defaultURL) { self.url = url }
    
    func loadItem() -> Item?
    {
        let manager = FileManager.default
        
        guard manager.fileExists(atPath: url.path) else
        {
            let item = Item(text: NSFullUserName())
            
            save(item)
            
            return item
        }
        
        guard let item = DecodableItem(fileURL: url) else
        {
            let title = "Couldn't Read From \"\(url.lastPathComponent)\""
            
            let message = "Please ensure your file at \(url.path) is formatted correctly. Then restart Flowlist.\n\nBe careful to retain the JSON format when editing the file outside of Flowlist."
            
            log(error: message, title: title, forUser: true)
            
            return nil
        }
        
        return item
    }
    
    func save(_ item: Item)
    {
        if item.save(to: url) == nil
        {
            let fileString = self.url.absoluteString
            log(error: "Could not save items to " + fileString)
        }
    }
    
    // MARK: - URL
    
    let url: URL
    
    // MARK: - Default URL
    
    static var defaultURL: URL
    {
        let directory = URL.documentDirectory ?? Bundle.main.bundleURL
        let fileName = ItemJSONFile.defaultFileName
        
        return directory.appendingPathComponent(fileName)
    }
    
    private static let defaultFileName: String =
    {
        #if DEBUG
        return "flowlist_debug.json"
        #elseif BETA
        return "flowlist_beta.json"
        #else
        return "flowlist.json"
        #endif
    }()
}
