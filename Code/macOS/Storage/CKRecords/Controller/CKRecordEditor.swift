import CloudKit
import PromiseKit
import SwiftyToolz

class CKRecordEditor
{
    func saveCKRecords(for records: [Record]) -> Promise<Void>
    {
        return firstly
        {
            ckRecordDatabase.save(records.map(self.makeCKRecord))
        }
        .then
        {
            saveResult -> Promise<Void> in
            
            try self.ensureNoFailures(in: saveResult)
            
            if saveResult.conflicts.isEmpty { return Promise() }
            
            return firstly
            {
                Dialog.default.askWhetherToPreferICloud()
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
    
    private var queue: DispatchQueue { return ckRecordDatabase.queue }
    private var ckRecordDatabase: CKRecordDatabase { return .shared }
}
