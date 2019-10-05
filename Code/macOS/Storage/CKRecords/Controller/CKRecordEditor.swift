import CloudKit
import FoundationToolz
import PromiseKit
import SwiftyToolz

class CKRecordEditor
{
    func saveCKRecords(for records: [Record]) -> Promise<Void>
    {
        guard !records.isEmpty else { return Promise() }
        
        return firstly
        {
            ckRecordDatabase.save(records.map(makeCKRecord))
        }
        .then
        {
            saveResult -> Promise<Void> in
            
            try self.ensureNoFailures(in: saveResult)
            
            if saveResult.conflicts.isEmpty { return Promise() }
            
            return firstly
            {
                self.askWhetherToPreferICloud(with: saveResult.conflicts)
            }
            .then
            {
                preferICloud -> Promise<Void> in
                
                guard !preferICloud else
                {
                    let serverRecords = saveResult.conflicts.map { $0.serverRecord.makeRecord() }
                    FileDatabase.shared.save(serverRecords, identifyAs: self)
                    return Promise()
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
    
    private func askWhetherToPreferICloud(with conflicts: [CKDatabase.SaveConflict]) -> Promise<Bool>
    {
        let text =
        """
        Seems like you changed items on this device without syncing with iCloud while another device changed the iCloud items. Now it's unclear how to combine both changes.

        Do you want to use the local- or the iCloud version? Note that Flowlist will overwrite the other location.
        """
        
        let serverContext = conflicts.compactMap({ $0.serverRecord.modificationDate }).optionContext
        let serverOption = "iCloud Items\(serverContext)"
        
        let clientContext = conflicts.compactMap({ $0.clientRecord.modificationDate }).optionContext
        let clientOption = "Local Items\(clientContext)"
        
        let question = Dialog.Question(title: "Conflicting Changes",
                                       text: text,
                                       options: [clientOption, serverOption])
        
        return firstly
        {
            Dialog.default.pose(question, imageName: "icloud_conflict")
        }
        .map(on: DispatchQueue.global(qos: .userInitiated))
        {
            guard $0.options.count == 1, let option = $0.options.first else
            {
                let errorMessage = "Unexpected # of answer options"
                log(error: errorMessage)
                throw errorMessage
            }
            
            return option == serverOption
        }
    }
    
    private func saveExpectingNoConflicts(_ records: [CKRecord]) -> Promise<Void>
    {
        return firstly
        {
            ckRecordDatabase.save(records)
        }
        .done
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
    
    func deleteCKRecords(with ids: [Record.ID]) -> Promise<Void>
    {
        guard !ids.isEmpty else { return Promise() }
        
        return firstly
        {
            ckRecordDatabase.deleteCKRecords(with: .ckRecordIDs(ids))
        }
        .done
        {
            if let firstFailure = $0.failures.first
            {
                throw "Couldn't delete items from iCloud. At least \($0.failures.count) deletions failed. First encountered error: \(firstFailure.error.ckReadable.message)"
            }
        }
    }
    
    private var queue: DispatchQueue { ckRecordDatabase.queue }
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
