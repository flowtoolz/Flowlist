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
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            {
                return records(from: json, parent: nil, position: 0)
            }
            else
            {
                return nil
            }
        }
        catch
        {
            log(error: error.localizedDescription)
            return nil
        }
    }
    
    var exists: Bool
    {
        FileManager.default.itemExists(url)
    }
    
    private func records(from json: [String: Any],
                         parent: Record.ID?,
                         position: Int) -> [Record]
    {
        guard let id = json["id"] as? String else { return [] }
        
        let textObject = json["title"]
        let text = (textObject as? String) ?? ((textObject as? [String: Any])?["storedValue"] as? String)
        
        let stateObject = json["state"]
        let stateInt = (stateObject as? Int) ?? ((stateObject as? [String: Any])?["storedValue"] as? Int)
        
        let tagObject = json["tag"]
        let tagInt = (tagObject as? Int) ?? ((tagObject as? [String: Any])?["storedValue"] as? Int)
        
        let loadedRecord = Record(id: id,
                                  text: text,
                                  state: ItemData.State(integer: stateInt),
                                  tag: ItemData.Tag(integer: tagInt),
                                  parent: parent,
                                  position: position)
        
        var loadedRecords = [loadedRecord]
        
        if let subJSONs = json["subtasks"] as? [[String: Any]]
        {
            for position in 0 ..< subJSONs.count
            {
                loadedRecords += records(from: subJSONs[position],
                                         parent: id,
                                         position: position)
            }
        }
        
        return loadedRecords
    }
    
    func remove()
    {
        FileManager.default.remove(url)
    }
    
    private(set) lazy var url: URL =
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
