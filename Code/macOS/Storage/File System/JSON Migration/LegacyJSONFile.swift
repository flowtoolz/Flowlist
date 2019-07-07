import Foundation
import FoundationToolz
import SwiftyToolz

class LegacyJSONFile
{
    func loadRecords() -> [Record]?
    {
        guard exists else { return [] }
        
        do
        {
            let data = try Data(contentsOf: url)
            
            if let json = try JSONSerialization.jsonObject(with: data) as? JSON
            {
                return records(from: json, withRootID: nil, position: 0)
            }
            else
            {
                return nil
            }
        }
        catch
        {
            log(error: error.readable.message)
            return nil
        }
    }
    
    var exists: Bool
    {
        return FileManager.default.itemExists(url)
    }
    
    private func records(from json: JSON,
                         withRootID rootID: Record.ID?,
                         position: Int) -> [Record]
    {
        guard let id = json["id"] as? String else { return [] }
        
        let textObject = json["title"]
        let text = (textObject as? String) ?? ((textObject as? JSON)?["storedValue"] as? String)
        
        let stateObject = json["state"]
        let stateInt = (stateObject as? Int) ?? ((stateObject as? JSON)?["storedValue"] as? Int)
        
        let tagObject = json["tag"]
        let tagInt = (tagObject as? Int) ?? ((tagObject as? JSON)?["storedValue"] as? Int)
        
        let loadedRecord = Record(id: id,
                                  text: text,
                                  state: ItemData.State(integer: stateInt),
                                  tag: ItemData.Tag(integer: tagInt),
                                  rootID: rootID,
                                  position: position)
        
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
    
    func remove()
    {
        FileManager.default.remove(url)
    }
    
    private lazy var url: URL =
    {
        let jsonFileDirectory = directory ?? Bundle.main.bundleURL
        return jsonFileDirectory.appendingPathComponent(name)
    }()
    
    private let name: String =
    {
        #if DEBUG
        return "flowlist_debug.json"
        #elseif BETA
        return "flowlist_beta.json"
        #else
        return "flowlist.json"
        #endif
    }()
    
    private let directory: URL? = .documentDirectory
}
