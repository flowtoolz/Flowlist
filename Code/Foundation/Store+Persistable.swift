import FoundationToolz
import SwiftObserver
import SwiftyToolz

extension Store: Persistable
{    
    // MARK: - Load & Save
    
    func load()
    {
        guard let fileUrl = fileUrl else { return }
        
        guard FileManager.default.fileExists(atPath: fileUrl.path) else
        {
            createFile()
            pasteWelcomeTourIfRootIsEmpty()
            
            return
        }
        
        guard let loadedRoot = DecodableItem(from: fileUrl) else
        {
            let title = "Couldn't Read From \"\(filename)\""
            
            let message = "Please ensure your file at \(fileUrl.path) is formatted correctly. Then restart Flowlist.\n\nBe careful to retain the JSON format when editing the file outside of Flowlist."
            
            log(error: message, title: title, forUser: true)
            
            return
        }
        
        loadedRoot.recoverNumberOfLeafs()
        loadedRoot.data.text <- NSFullUserName()
        
        update(root: loadedRoot)
        
        pasteWelcomeTourIfRootIsEmpty()
    }
    
    private func createFile()
    {
        guard let root = root else { return }
        
        root.data.text <- NSFullUserName()
        save()
    }
    
    func save()
    {
        guard let root = root,
            let fileUrl = fileUrl,
            let _ = root.save(to: fileUrl)
        else
        {
            let fileString = self.fileUrl?.absoluteString ?? "file"
            log(error: "Failed to save items to " + fileString)
            return
        }
    }
    
    // MARK: - File URL
    
    private var fileUrl: URL?
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
