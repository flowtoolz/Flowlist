import FoundationToolz
import SwiftObserver
import SwiftyToolz

class FileSystemRecordPersister: RecordPersister
{
    /// Experimental Loading of Records
    
    func loadRecords() -> [Record]
    {
        guard FileManager.default.fileExists(atPath: url.path) else
        {
            let rootRecord = newRootRecord
            save(rootRecord.makeItem())
            return [rootRecord]
        }
        
        do
        {
            let data = try Data(contentsOf: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? JSON
            {
                return records(from: json, withRootID: nil, position: 0)
            }
        }
        catch
        {
            log(error: error.readable.message)
        }
        
        return [newRootRecord]
    }
    
    private func records(from json: JSON,
                         withRootID rootID: String?,
                         position: Int) -> [Record]
    {
        guard let id = json["id"] as? String else { return [] }
        
        let loadedRecord = Record(id: id,
                                  text: json["title"] as? String,
                                  state: ItemData.State(integer: json["state"] as? Int),
                                  tag: ItemData.Tag(integer: json["tag"] as? Int),
                                  rootID: rootID,
                                  position: position)
        
        //print("loaded record: \(loadedRecord.text ?? "<nil text>")")
        
        var loadedRecords = [loadedRecord]
        
        if let subJSONs = json["subtasks"] as? [JSON]
        {
            for position in 0 ..< subJSONs.count
            {
                loadedRecords += records(from: subJSONs[position],
                                         withRootID: id,
                                         position: position)
            }
        }
        
        return loadedRecords
    }
    
    private var newRootRecord: Record
    {
        return Record(id: .makeUUID(), text: NSFullUserName(), rootID: nil, position: 0)
    }
    
    ///
    
    init(url: URL = FileSystemRecordPersister.defaultURL) { self.url = url }
    
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
        let fileName = FileSystemRecordPersister.defaultFileName
        
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
