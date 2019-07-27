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
        
        guard FileDatabase.shared.loadFiles().isEmpty else
        {
            informUserThatLegacyJSONFileReappeared(filePath: jsonFile.url.path)
            return Promise()
        }
        
        guard FileDatabase.shared.save(jsonFileRecords, identifyAs: self, sendEvent: false) else
        {
            return .fail("Found JSON File but can't migrate its content. Saving the items as files failed.")
        }
        
        jsonFile.remove()
        
        return Promise()
    }

    func informUserThatLegacyJSONFileReappeared(filePath: String)
    {
        let text =
        """
        This file reappeared, maybe you put it back there:
        \(filePath)
        
        Flowlist up to version 1.7.1 saved your items there. If you wanna migrate those items again to the new format, make sure the new item folder is empty on app start:
        \(FileDatabase.shared.directory)
        
        Flowlist deletes the old JSON file after migration.
        """
        
        let question = Dialog.Question(title: "Legacy JSON File Reappeared",
                                       text: text,
                                       options: ["Got It"])
        
        Dialog.default.pose(question).catch { log(error: $0.readable.message) }
    }
}
