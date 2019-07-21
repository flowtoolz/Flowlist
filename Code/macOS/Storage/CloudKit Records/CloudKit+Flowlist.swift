import CloudKit

extension CKRecord.RecordType
{
    static var item: CKRecord.RecordType { return "Item" }
}

extension CKRecord.ID
{
    convenience init(itemID: String)
    {
        self.init(recordName: itemID, zoneID: .item)
    }
}

extension CKRecordZone.ID
{
    static var item: CKRecordZone.ID
    {
        return CKRecordZone.ID(zoneName: "ItemZone",
                               ownerName: CKCurrentUserDefaultName)
    }
}

extension CKRecord.Reference
{
    // TODO: start using CKRecord.parent reference property in addition so we can migrate to that property at some point
    convenience init(itemOwnerName: String)
    {
        self.init(recordID: CKRecord.ID(itemID: itemOwnerName),
                  action: .deleteSelf)
    }
}
