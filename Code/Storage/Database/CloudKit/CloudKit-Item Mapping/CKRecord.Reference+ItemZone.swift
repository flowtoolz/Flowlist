import CloudKit

extension CKRecord.Reference
{
    // TODO: start using CKRecord.parent reference property in addition so we can migrate to that property at some point
    convenience init(itemOwnerName: String)
    {
        self.init(recordID: CKRecord.ID(itemID: itemOwnerName),
                  action: .deleteSelf)
    }
}
