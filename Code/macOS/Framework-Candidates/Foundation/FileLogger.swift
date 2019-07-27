import FoundationToolz
import Foundation
import SwiftyToolz

class FileLogger: LogObserver
{
    // MARK: - Life Cycle
    
    init(_ file: URL)
    {
        self.file = file
        Log.shared.add(observer: self)
    }
    
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
            log(error: error.localizedDescription)
        }
    }
    
    private var logString: String
    {
        return logs.reduce(into: "\(appName ?? "App") Debug Log")
        {
            $0.append("\n\n\($1.description))")
        }
    }
    
    // MARK: - File URL
    
    private let file: URL
    
    // MARK: - Observe Log
    
    func receive(_ entry: Log.Entry)
    {
        logs.append(entry)
    }
    
    private var logs = [Log.Entry]()
}
