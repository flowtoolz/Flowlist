import Foundation
import SwiftObserver

class TaskArchive: NSObject, NSCoding
{
    required convenience init?(coder aDecoder: NSCoder)
    {
        guard let decodedUuid = aDecoder.decodeObject(forKey: "uuid") as? String else
        {
            Swift.print("Error decoding Task: could not decode UUID string")
            return nil
        }
        
        let decodedTask = Task()
        
        decodedTask.title <- aDecoder.decodeObject(forKey: "title") as? String
        
        if let state = LegacyState(rawValue: aDecoder.decodeInteger(forKey: "state"))
        {
            switch state
            {
            case .done: decodedTask.state <- .done
            default: break
            }
        }
        
        self.init(with: decodedTask, uuid: decodedUuid)

        elementUuidsForDecoding = aDecoder.decodeObject(forKey: "elementUuids") as? [String]
    }
    
    var elementUuidsForDecoding: [String]?
    
    func encode(with aCoder: NSCoder) { fatalError() }
    
    init(with task: Task, uuid: String)
    {
        self.task = task
        self.uuid = uuid
    }
    
    let task: Task
    let uuid: String
}

enum LegacyState: Int
{
    // state == nil is default and kind of a backlog or "no specific state"
    case inProgress, onHold, done, archived
}
