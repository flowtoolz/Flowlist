import UIToolz
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
        
        guard let loadedRoot = Item(from: fileUrl) else
        {
            log(error: "Failed to load items from " + fileUrl.absoluteString)
            
            let message = "Please ensure that your data file \"\(fileUrl.path)\" is formatted correctly. Then restart Flowlist.\n\n(Be careful to retain the JSON format when editing the file outside of Flowlist.)"
            
            // TODO: This file depends on AppKit just because this alert. Avoid that.
            show(alert: message, title: "Couldn't Read From \"\(filename)\"")
            
            return
        }
        
        loadedRoot.recoverRoots()
        loadedRoot.recoverNumberOfLeafs()
        loadedRoot.data?.text <- NSFullUserName()
        
        set(newRoot: loadedRoot)
        
        pasteWelcomeTourIfRootIsEmpty()
    }
    
    private func createFile()
    {
        guard let root = root else { return }
        
        root.data?.text <- NSFullUserName()
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
