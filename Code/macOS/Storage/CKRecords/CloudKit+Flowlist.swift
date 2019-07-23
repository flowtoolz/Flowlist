import CloudKit

extension CKRecord.RecordType
{
    static var itemType: CKRecord.RecordType { return "Item" }
}

extension CKRecord.Reference
{
    // TODO: start using CKRecord.parent reference property in addition so we can migrate to that property at some point
    convenience init(parent: Record.ID)
    {
        self.init(recordID: .init(parent), action: .deleteSelf)
    }
}

extension Array where Element == CKRecord.ID
{
    static func ckRecordIDs(_ ids: [Record.ID]) -> [CKRecord.ID]
    {
        return ids.map(CKRecord.ID.init(_:))
    }
}

extension CKRecord.ID
{
    convenience init(_ recordID: Record.ID)
    {
        self.init(recordName: recordID, zoneID: .itemZone)
    }
}

extension CKRecordZone.ID
{
    static var itemZone: CKRecordZone.ID
    {
        return CKRecordZone.ID(zoneName: "ItemZone",
                               ownerName: CKCurrentUserDefaultName)
    }
}

extension CKSubscription.ID
{
    static var itemSub: CKSubscription.ID { return CKSubscription.ID("ItemDataBaseSubscription") }
}
