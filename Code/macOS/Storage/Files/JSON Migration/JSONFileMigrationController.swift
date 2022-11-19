import Foundation
import SwiftObserver
import SwiftyToolz

class JSONFileMigrationController
{
    func migrateJSONFile() async throws
    {
        let jsonFile = LegacyJSONFile()
        
        guard
            jsonFile.exists,
            let jsonFileRecords = jsonFile.loadRecords(),
            !jsonFileRecords.isEmpty
        else { return }
        
        guard FileDatabase.shared.loadFiles().isEmpty else
        {
            try await informUserThatLegacyJSONFileReappeared(filePath: jsonFile.url.path)
            return
        }
        
        guard FileDatabase.shared.save(jsonFileRecords, as: self, sendEvent: false) else
        {
            throw "Found JSON File but can't migrate its content. Saving the items as files failed."
        }
        
        jsonFile.remove()
    }

    func informUserThatLegacyJSONFileReappeared(filePath: String) async throws
    {
        let text =
        """
        This file reappeared, maybe you put it back there:
        \(filePath)
        
        Flowlist up to version 1.7.1 saved your items there. If you wanna migrate those items again to the new format, make sure the new item folder is empty on app start:
        \(FileDatabase.shared.directory)
        
        Flowlist deletes the old JSON file after migration.
        """
        
        let question = Question(title: "Legacy JSON File Reappeared",
                                       text: text,
                                       options: ["Got It"])
        
        _ = try await Dialog.default?.pose(question)
    }
}
