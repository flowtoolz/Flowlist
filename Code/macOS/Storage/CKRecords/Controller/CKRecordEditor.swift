import CloudKit
import FoundationToolz
import SwiftObserver
import SwiftyToolz

class CKRecordEditor
{
    func saveCKRecords(for records: [Record]) -> ResultPromise<Void>
    {
        guard !records.isEmpty else { return .fulfilled(()) }
        
        return promise
        {
            ckRecordDatabase.save(records.map(makeCKRecord))
        }
        .onSuccess
        {
            saveResult -> ResultPromise<Void> in
            
            try self.ensureNoFailures(in: saveResult)
            
            if saveResult.conflicts.isEmpty { return .fulfilled(()) }
            
            return promise
            {
                self.askWhetherToPreferICloud(with: saveResult.conflicts)
            }
            .onSuccess
            {
                preferICloud -> ResultPromise<Void> in
                
                guard !preferICloud else
                {
                    let serverRecords = saveResult.conflicts.map { $0.serverRecord.makeRecord() }
                    FileDatabase.shared.save(serverRecords, as: self)
                    return .fulfilled(())
                }
                
                let resolvedServerRecords = saveResult.conflicts.map
                {
                    conflict -> CKRecord in
                    
                    let clientRecord = conflict.clientRecord
                    let serverRecord = conflict.serverRecord
                    
                    serverRecord.text = clientRecord.text
                    serverRecord.state = clientRecord.state
                    serverRecord.tag = clientRecord.tag
                    serverRecord.superItem = clientRecord.superItem
                    serverRecord.position = clientRecord.position
                
                    return serverRecord
                }
                
                return self.saveExpectingNoConflicts(resolvedServerRecords)
            }
        }
    }
    
    private func askWhetherToPreferICloud(with conflicts: [CKDatabase.SaveConflict]) -> ResultPromise<Bool>
    {
        guard let dialog = Dialog.default else
        {
            return .fulfilled("Default Dialog has not been set")
        }
        
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
        
        return promise
        {
            dialog.pose(question, imageName: "icloud_conflict")
        }
        .mapSuccess
        {
            guard $0.options.count == 1, let option = $0.options.first else
            {
                let error: Error = "Unexpected # of answer options"
                log(error)
                throw error
            }
            
            return option == serverOption
        }
    }
    
    private func saveExpectingNoConflicts(_ records: [CKRecord]) -> ResultPromise<Void>
    {
        promise
        {
            ckRecordDatabase.save(records)
        }
        .mapSuccess
        {
            saveResult -> Void in
            
            try self.ensureNoFailures(in: saveResult)
            
            guard saveResult.conflicts.isEmpty else
            {
                throw "Couldn't save items in iCloud due to \(saveResult.conflicts.count) unexpected conflicts."
            }
        }
    }
    
    private func ensureNoFailures(in saveResult: CKDatabase.SaveResult) throws
    {
        if let firstFailure = saveResult.partialFailures.first
        {
            throw "Couldn't update items in iCloud. At least \(saveResult.partialFailures.count) updates failed. First encountered error: \(firstFailure.error.ckReadable.message)"
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
    
    func deleteCKRecords(with ids: [Record.ID]) -> ResultPromise<Void>
    {
        guard !ids.isEmpty else { return .fulfilled(()) }
        
        return promise
        {
            ckRecordDatabase.deleteCKRecords(with: .ckRecordIDs(ids))
        }
        .mapSuccess
        {
            if let firstFailure = $0.partialFailures.first
            {
                throw "Couldn't delete items from iCloud. At least \($0.partialFailures.count) deletions failed. First encountered error: \(firstFailure.error.ckReadable.message)"
            }
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
