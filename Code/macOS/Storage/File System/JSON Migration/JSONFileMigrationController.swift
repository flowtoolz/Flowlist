import Foundation
import PromiseKit
import SwiftyToolz

class JSONFileMigrationController
{
    func migrateJSONFile() -> Promise<Void>
    {
        let jsonFile = LegacyJSONFile()
        
        guard jsonFile.exists,
            let jsonFileRecords = jsonFile.loadRecords(),
            !jsonFileRecords.isEmpty
            else
        {
            return Promise()
        }
        
        guard FileSystemDatabase.shared.recordFileDirectory != nil else
        {
            return Promise(error: ReadableError.message("Found JSON File but can't migrate its content. Can't access the targeted folder."))
        }
        
        // TODO: check if there are already files in the new file based database. if so, ask user (async via class Dialog) which records to use. possibly even offer to be sure and use both. hint that json file will be deleted to avoid confusion in the future.
        
        guard FileSystemDatabase.shared.save(jsonFileRecords) else
        {
            return Promise(error: ReadableError.message("Found JSON File but can't migrate its content. Saving the items as files failed."))
        }
        
        jsonFile.remove()
        
        return Promise()
    }
}
