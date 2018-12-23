import Foundation
import SwiftyToolz

class FileLogger: LogObserver
{
    init() { Log.shared.notify(self) }
    
    deinit { Log.shared.stopNotifying(self) }
    
    func process(_ entry: Log.Entry)
    {
        logs.append(entry)
    }
    
    func saveLogsToFile()
    {
        guard let docDirURL = URL.documentDirectory else
        {
            log(error: "Could not get documents directory URL.")
            return
        }
        
        let fileName = "flowlist-log.txt"
        let filePath = docDirURL.appendingPathComponent(fileName).path
        let fileURL = URL(fileURLWithPath: filePath)
        
        do
        {
            try logString.write(to: fileURL,
                                atomically: false,
                                encoding: .utf8)
        }
        catch let error
        {
            log(error: error.localizedDescription)
        }
    }
    
    private var logString: String
    {
        return logs.reduce(into: "Flowlist Debug Log")
        {
            $0.append("\n\n\(Log.shared.string(for: $1))")
        }
    }
    
    private var logs = [Log.Entry]()
}
