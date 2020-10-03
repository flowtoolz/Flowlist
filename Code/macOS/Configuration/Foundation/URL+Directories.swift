import FoundationToolz
import Foundation
import SwiftyToolz

extension URL
{
    static let flowlistDirectory: URL =
    {
        let dir = mainDirectory.appendingPathComponent(flowlistDirectoryName)
        FileManager.default.ensureDirectoryExists(dir)
        return dir
    }()
    
    private static var flowlistDirectoryName: String
    {
        #if BETA
        return "Flowlist-Beta"
        #elseif DEBUG
        return "Flowlist-Debug"
        #else
        return "Flowlist"
        #endif
    }
    
    private static var mainDirectory: URL
    {
        guard let documentDirectory = URL.documentDirectory else
        {
            log(error: "Couldn't access document directory. Gonna use main bundle directory.")
            return Bundle.main.bundleURL
        }
        
        return documentDirectory
    }
}
