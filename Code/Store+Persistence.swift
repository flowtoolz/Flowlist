import UIToolz
import FoundationToolz
import SwiftObserver
import SwiftyToolz

extension Store
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
        
        guard let loadedRoot = Task(from: fileUrl) else
        {
            didLoadTasksSuccessfully = false
            
            log(error: "Failed to load tasks from " + fileUrl.absoluteString)
            
            let message = "Please ensure that your data file \"\(fileUrl.path)\" is formatted correctly. Then restart Flowlist.\n\n(Be careful to retain the JSON format when editing the file outside of Flowlist.)"
            
            show(alert: message, title: "Couldn't Read From \"\(filename)\"")
            
            return
        }
        
        didLoadTasksSuccessfully = true
        
        loadedRoot.recoverRoots()
        loadedRoot.recoverNumberOfLeafs()
        loadedRoot.data?.title <- NSFullUserName()
        
        root = loadedRoot
        
        pasteWelcomeTourIfRootIsEmpty()
    }
    
    private func createFile()
    {
        root.data?.title <- NSFullUserName()
        didLoadTasksSuccessfully = true
        save()
    }
    
    func save()
    {
        guard didLoadTasksSuccessfully,
            let fileUrl = fileUrl,
            let _ = root.save(to: fileUrl)
        else
        {
            let fileString = self.fileUrl?.absoluteString ?? "file"
            log(error: "Failed to save tasks to " + fileString)
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

fileprivate var didLoadTasksSuccessfully = false
