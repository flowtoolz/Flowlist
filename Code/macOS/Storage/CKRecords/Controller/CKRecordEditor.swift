import CloudKit
import FoundationToolz
import SwiftyToolz

class CKRecordEditor
{
    func saveCKRecords(for records: [Record]) async throws
    {
        guard !records.isEmpty else { return }
        
        let saveResult = try await ckRecordDatabase.save(records.map(makeCKRecord))
        
        try ensureNoFailures(in: saveResult)
        
        if saveResult.conflicts.isEmpty { return }
        
        // no failures but some conflicts -> ask user how to proceed
        
        let useRecordsFromICloud = try await askWhetherToPreferICloud(with: saveResult.conflicts)
        
        if useRecordsFromICloud // -> save iCloud records locally
        {
            let serverRecords = saveResult.conflicts.map { $0.serverRecord.makeRecord() }
            FileDatabase.shared.save(serverRecords, as: self)
        }
        else // use local records -> save local records to iCloud
        {
            let resolvedServerRecords: [CKRecord] = saveResult.conflicts.map
            {
                let clientRecord = $0.clientRecord
                let serverRecord = $0.serverRecord
                
                serverRecord.text = clientRecord.text
                serverRecord.state = clientRecord.state
                serverRecord.tag = clientRecord.tag
                serverRecord.superItem = clientRecord.superItem
                serverRecord.position = clientRecord.position
                
                return serverRecord
            }
            
            try await saveExpectingNoConflicts(resolvedServerRecords)
        }
    }
    
    private func askWhetherToPreferICloud(with conflicts: [CKDatabase.SaveResult.Conflict]) async throws -> Bool
    {
        guard let dialog = Dialog.default else { throw "Default Dialog has not been set" }
        
        let text =
        """
        Seems like you changed items on this device without syncing with iCloud while another device changed the iCloud items. Now it's unclear how to combine both changes.

        Do you want to use the local- or the iCloud version? Note that Flowlist will overwrite the other location.
        """
        
        let serverContext = conflicts.compactMap({ $0.serverRecord.modificationDate }).optionContext
        let serverOption = "iCloud Items\(serverContext)"
        
        let clientContext = conflicts.compactMap({ $0.clientRecord.modificationDate }).optionContext
        let clientOption = "Local Items\(clientContext)"
        
        let question = Question(title: "Conflicting Changes",
                                text: text,
                                options: [clientOption, serverOption])
        
        let answer = try await dialog.pose(question, imageName: "icloud_conflict")
        
        guard let option = answer.options.first else { throw "Answer contains has no options selected" }
            
        if answer.options.count != 1 { log(warning: "Answer has \(answer.options.count) selected but we expected 1") }
        
        return option == serverOption
    }
    
    private func saveExpectingNoConflicts(_ records: [CKRecord]) async throws
    {
        let saveResult = try await ckRecordDatabase.save(records)
           
        try ensureNoFailures(in: saveResult)
        
        if !saveResult.conflicts.isEmpty
        {
            throw "Couldn't save items in iCloud due to \(saveResult.conflicts.count) unexpected conflicts."
        }
    }
    
    private func ensureNoFailures(in saveResult: CKDatabase.SaveResult) throws
    {
        if let firstFailure = saveResult.failures.first
        {
            throw "Couldn't update items in iCloud. At least \(saveResult.failures.count) updates failed. First encountered error: \(firstFailure.error.ckReadable.message)"
        }
    }

    private func makeCKRecord(for record: Record) -> CKRecord
    {
        let ckRecord = ckRecordDatabase.getCKRecordWithCachedSystemFields(for: .init(record.id))
        
        ckRecord.text = record.text
        ckRecord.state = record.state
        ckRecord.tag = record.tag
        
        ckRecord.superItem = record.parent
        ckRecord.position = record.position
        
        return ckRecord
    }
    
    func deleteCKRecords(with ids: [Record.ID]) async throws
    {
        guard !ids.isEmpty else { return }
        
        let deletionResult = try await ckRecordDatabase.deleteCKRecords(with: .ckRecordIDs(ids))
        
        if let firstFailure = deletionResult.failures.first
        {
            throw "Couldn't delete items from iCloud. At least \(deletionResult.failures.count) deletions failed. First encountered error: \(firstFailure.value.ckReadable.message)"
        }
    }
    
    private var ckRecordDatabase: CKRecordDatabase { .shared }
}

private extension Array where Element == Date
{
    var optionContext: String
    {
        guard let latest = latest,
            let passedDays = Date().days(since: latest) else { return "" }
        
        return " (Last conflict: \(passedDays) day\(passedDays != 1 ? "s" : "") ago)"
    }
}
