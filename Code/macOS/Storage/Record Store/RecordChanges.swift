struct RecordChanges: Equatable
{
    let modifiedRecords: [Record]
    let idsOfDeletedRecords: [String]
    var hasChanges: Bool { return modifiedRecords.count + idsOfDeletedRecords.count > 0 }
}
