import CloudKit

extension CKRecord.RecordType
{
    static var itemType: CKRecord.RecordType { "Item" }
}

extension CKRecord.Reference
{
    convenience init(parent: Record.ID)
    {
        self.init(recordID: .init(parent), action: .deleteSelf)
    }
}

extension Array where Element == CKRecord.ID
{
    static func ckRecordIDs(_ ids: [Record.ID]) -> [CKRecord.ID]
    {
        ids.map(CKRecord.ID.init(_:))
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
        CKRecordZone.ID(zoneName: "ItemZone",
                        ownerName: CKCurrentUserDefaultName)
    }
}

extension CKSubscription.ID
{
    static var itemSub: CKSubscription.ID { CKSubscription.ID("ItemDataBaseSubscription") }
}

var isCKSyncFeatureAvailable: Bool { true }
