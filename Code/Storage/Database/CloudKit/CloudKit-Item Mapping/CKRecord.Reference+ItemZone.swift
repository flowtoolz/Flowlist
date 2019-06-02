import CloudKit

extension CKRecord.Reference
{
    convenience init(itemOwnerName: String)
    {
        self.init(recordID: CKRecord.ID(itemID: itemOwnerName),
                  action: .deleteSelf)
    }
}
