import CloudKit

extension CKRecordZone.ID
{
    static var item: CKRecordZone.ID
    {
        return CKRecordZone.ID(zoneName: "ItemZone",
                               ownerName: CKCurrentUserDefaultName)
    }
}
