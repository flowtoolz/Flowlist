import CloudKit
import SwiftObserver
import PromiseKit

extension ItemICloudDatabase
{
    func fetchItemTree(handleResult: @escaping ItemTreeHandler)
    {
        fetchAllItemRecords
        {
            guard let records = $0 else
            {
                log(error: "Couldn't fetch records.")
                handleResult(false, nil)
                return
            }
            
            guard !records.isEmpty else
            {
                handleResult(true, nil)
                return
            }
            
            guard let root = Item(records: records) else
            {
                log(error: "Couldn't create item tree from records.")
                handleResult(false, nil)
                return
            }
            
            handleResult(true, root)
        }
    }
    
    private func fetchAllItemRecords(handleResult: @escaping ([CKRecord]?) -> Void)
    {
        firstly
        {
            fetchAllUpdates()
        }
        .done
        {
            handleResult($0.changedRecords)
        }
        .catch
        {
            log($0)
            handleResult(nil)
        }
    }
}
