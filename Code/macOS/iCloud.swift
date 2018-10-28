import CloudKit
import SwiftObserver
import SwiftyToolz

class ICloud
{
    // MARK: - Testing
    
    func test()
    {
        print("TESTING ICLOUD")
        
        container.accountStatus
        {
            status, error in
            
            if let error = error
            {
                print("An error occured requesting the iCloud account status: \(error.localizedDescription)")
                return
            }
            
            switch status
            {
            case .couldNotDetermine:
                print("Could not determine iCloud account status.")
            case .available:
                print("iCloud account is available.")
                //self.save(itemTree: store.root)
                //self.fetchItemTree { $0?.debug() }
            case .restricted:
                print("iCloud account is restricted.")
            case .noAccount:
                print("This device is not connected to an iCloud account.")
            }
        }
    }
    
    // MARK: - Observe Changes in iCloud

    func didReceiveRemoteNotification(with userInfo: [String : Any])
    {
        let notification = CKNotification(fromRemoteNotificationDictionary: userInfo)
        
        guard notification.notificationType == .query,
            let queryNotification = notification as? CKQueryNotification
        else
        {
            return
        }
    
        guard let recordId = queryNotification.recordID else
        {
            log(error: "iCloud query notification carries no record id.")
            // TODO: could this ever happen? how is it to be handled?? reload all data from icloud??
            return
        }
        
        let changedFields = queryNotification.recordFields
        
        let isUntouched = !queryNotification.isPruned
        let carriesMaximumFields = changedFields?.count == desiredTags.count
        let carriesAllRelevantFields = isUntouched || carriesMaximumFields
        
        switch queryNotification.queryNotificationReason
        {
        case .recordCreated:
            print("did create record: <\(recordId.recordName)>")
            print("new fields: \(changedFields?.debugDescription ?? "nil")")
            print("fields are complete: \(carriesAllRelevantFields)")
            
        case .recordUpdated:
            print("did change record: <\(recordId.recordName)>")
            print("new fields: \(changedFields?.debugDescription ?? "nil")")
            print("fields are complete: \(carriesAllRelevantFields)")
            
        case .recordDeleted:
            print("did delete record: <\(recordId.recordName)>")
        }
    }
    
    private func setupSubscription()
    {
        let options: CKSubscriptionOptions =
        [
            .firesOnRecordUpdate,
            .firesOnRecordCreation,
            .firesOnRecordDeletion
        ]
        
        let subscription = CKSubscription(recordType: "Item",
                                          predicate: NSPredicate(value: true),
                                          options: options)
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.alertLocalizationKey = "Items where changed in iCloud."
        notificationInfo.shouldBadge = false
        notificationInfo.desiredKeys = desiredTags
        
        subscription.notificationInfo = notificationInfo
        
        database.save(subscription)
        {
            savedSubscription, error in
            
            if let error = error
            {
                print("Could not save iCloud subscription. Error: \(error.localizedDescription)")
                return
            }
            
            print("Saved iCloud subscription: \(savedSubscription.debugDescription)")
        }
    }
    
    private let desiredTags = ["text", "tag", "state", "superItem"]
    
    // MARK: - Save Item Tree to iCloud
    
    private func save(itemTree root: Item)
    {
        let itemRecords = records(fromItemTree: root)
        
        let operation = CKModifyRecordsOperation(recordsToSave: itemRecords,
                                                 recordIDsToDelete: nil)
        
        operation.database = database
        operation.savePolicy = .changedKeys // TODO: or if server records unchanged? handle "merge conflicts" when multiple devices changed data locally offline...
        
        operation.perRecordCompletionBlock =
        {
            record, error in
            
            if let error = error
            {
                log(error: error.localizedDescription)
                
                // TODO: remember failed records and handle them / try again later...
            }
        }
        
        operation.modifyRecordsCompletionBlock =
        {
            records, _, error in
            
            if let error = error
            {
                log(error: error.localizedDescription)
            }
            
            print("Did save \(itemRecords.count) item records to iCloud.")
            // TODO: handle completion
        }
        
        operation.start()
    }
    
    private func records(fromItemTree root: Item) -> [CKRecord]
    {
        var result = [CKRecord]()
        
        if let record = root.ckRecord
        {
            result.append(record)
        }
        
        for subitem in root.branches
        {
            result.append(contentsOf: records(fromItemTree: subitem))
        }
        
        return result
    }
    
    // MARK: - Fetch & Connect Items
    
    private func fetchItemTree(receiveRoot: @escaping (Item?) -> Void)
    {
        fetchItemRecords()
        {
            records in receiveRoot(self.itemTree(from: records))
        }
    }
    
    private func itemTree(from records: [CKRecord]?) -> Item?
    {
        // get record array
        
        guard let records = records else
        {
            log(warning: "Record array is nil.")

            return nil
        }
        
        // create unconnected items. remember associated records.
        
        var hashMap = [String : (CKRecord, Item)]()
        
        for record in records
        {
            guard let data = ICloud.createItemData(from: record) else { continue }
            
            hashMap[data.id] = (record, Item(data: data))
        }
        
        // connect items. find root.
        
        var root: Item?
        
        for (record, item) in hashMap.values
        {
            guard let superItemReference: CKReference = record["superItem"] else
            {
                if root != nil
                {
                    log(error: "Record array contains more than 1 root.")
                    
                    return nil
                }
                
                root = item
                
                continue
            }
            
            let superItemId = superItemReference.recordID.recordName
            
            guard let (_, superItem) = hashMap[superItemId] else
            {
                log(error: "Record for super item with id \(superItemId) is missing.")
                
                return nil
            }
            
            item.root = superItem
            
            // TODO: persist and maintain item order
            superItem.add(item)
        }
        
        // return root
        
        if root == nil
        {
            log(error: "Record array contains no root.")
        }
        
        return root
    }
    
    // MARK: - Convert between Item & Record
    
    static func createItemData(from itemRecord: CKRecord) -> ItemData?
    {
        guard itemRecord.recordType == "Item" else
        {
            log(error: "Cannot create ItemData from iCloud record of type \"\(itemRecord.recordType)\". Expected\"Item\".")
            return nil
        }
        
        let data = ItemData(id: itemRecord.recordID.recordName)
        
        data.text <- itemRecord["text"]
        
        if let stateInt: Int = itemRecord["state"]
        {
            data.state <- ItemData.State(rawValue: stateInt)
        }
        
        if let tagInt: Int = itemRecord["tag"]
        {
            data.tag <- ItemData.Tag(rawValue: tagInt)
        }
        
        return data
    }
    
    // MARK: - Fetch Item Records
    
    private func fetchItemRecords(resultHandler: @escaping ([CKRecord]?) -> Void)
    {
        fetchItemRecords(with: NSPredicate(value: true),
                         resultHandler: resultHandler)
    }
    
    private func fetchSubitemRecords(of itemRecord: CKRecord,
                                     resultHandler: @escaping ([CKRecord]?) -> Void)
    {
        guard itemRecord.recordType == "Item" else { return }
        
        fetchSubitemRecords(withSuperItemID: itemRecord.recordID,
                            resultHandler: resultHandler)
    }
    
    private func fetchSubitemRecords(withSuperItemID id: CKRecordID,
                                     resultHandler: @escaping ([CKRecord]?) -> Void)
    {
        let predicate = NSPredicate(format: "superItem = %@", id)
        
        fetchItemRecords(with: predicate, resultHandler: resultHandler)
    }
    
    private func fetchItemRecords(with predicate: NSPredicate,
                                  resultHandler: @escaping ([CKRecord]?) -> Void)
    {
        let query = CKQuery(recordType: "Item", predicate: predicate)
        
        fetchRecords(with: query, resultHandler: resultHandler)
    }
    
    // MARK: - iCloud
    
    private func fetchRecords(with query: CKQuery,
                              resultHandler: @escaping ([CKRecord]?) -> Void)
    {
        database.perform(query, inZoneWith: .default)
        {
            records, error in
            
            if let error = error
            {
                log(error: "Could not fetch iCloud records. Error: \(error.localizedDescription)")
                resultHandler(nil)
                return
            }
            
            if records == nil
            {
                log(error: "Could not fetch iCloud records. The result array is nil.")
            }
            
            resultHandler(records)
        }
    }
    
    private func save(_ record: CKRecord,
                      resultHandler: @escaping (CKRecord?) -> Void)
    {
        database.save(record)
        {
            savedRecord, error in
            
            if let error = error
            {
                log(error: "Could not save iCloud record. Error: \(error.localizedDescription)")
                resultHandler(nil)
                return
            }
            
            if savedRecord == nil
            {
                log(error: "Could not save iCloud record. The result record is nil.")
            }
            
            resultHandler(savedRecord)
        }
    }
    
    private var database: CKDatabase
    {
        return container.privateCloudDatabase
    }
    
    private var container: CKContainer
    {
        return CKContainer.default()
    }
}

extension Tree where Data == ItemData
{
    var ckRecord: CKRecord? { return record(from: self) }
    
    private func record(from item: Item) -> CKRecord?
    {
        guard let data = item.data else
        {
            log(error: "Item has no data.")
            return nil
        }

        let result = CKRecord(recordType: "Item",
                              recordID: CKRecordID(recordName: data.id))
        
        result["text"] = item.text
        result["state"] = data.state.value?.rawValue
        result["tag"] = data.tag.value?.rawValue
        
        if let rootData = item.root?.data
        {
            let superItemId = CKRecordID(recordName: rootData.id)
            result["superItem"] = superItemId.ownerReference
        }
        
        return result
    }
}

extension CKRecordID
{
    var ownerReference: CKReference
    {
        return CKReference(recordID: self, action: .deleteSelf)
    }
}
