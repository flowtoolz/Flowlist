import FoundationToolz
import Foundation
import SwiftyToolz

// TODO: generalize and move to FoundationToolz

class FileLogger: LogObserver
{
    // MARK: - Life Cycle
    
    init() { Log.shared.add(observer: self) }
    deinit { Log.shared.remove(observer: self) }
    
    // MARK: - Save Log Entries to File
    
    func saveLogsToFile()
    {   
        do
        {
            try logString.write(to: file, atomically: false, encoding: .utf8)
        }
        catch
        {
            log(error: error.readable.message)
        }
    }
    
    private var logString: String
    {
        return logs.reduce(into: "Flowlist Debug Log")
        {
            $0.append("\n\n\($1.description))")
        }
    }
    
    // MARK: - File URL
    
    private let file = URL.flowlistDirectory.appendingPathComponent("flowlist-log.txt")
    
    // MARK: - Observe Log
    
    func receive(_ entry: Log.Entry)
    {
        logs.append(entry)
    }
    
    private var logs = [Log.Entry]()
}
