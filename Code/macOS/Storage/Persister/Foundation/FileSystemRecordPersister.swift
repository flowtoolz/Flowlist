import Foundation

class FileSystemRecordPersister: RecordPersister
{
    // MARK: - Load & Save
    
    func loadRecords() -> [Record]
    {
        return DeprecatedJSONFile().loadRecords(initialRoot: newRootRecord)
    }
    
    // TODO: save N records to N files rather than 1 item to 1 json file ...
    func save(_ item: Item)
    {
        DeprecatedJSONFile().save(item)
    }
    
    // MARK: - Basics
    
    let directory: URL? = .documentDirectory
    
    private var newRootRecord: Record
    {
        return Record(id: .makeUUID(), text: NSFullUserName(), rootID: nil, position: 0)
    }
}
