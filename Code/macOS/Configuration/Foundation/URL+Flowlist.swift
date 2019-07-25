import FoundationToolz
import SwiftyToolz

extension URL
{
    static let flowlistDirectory: URL =
    {
        let dir = mainDirectory.appendingPathComponent("Flowlist")
        FileManager.default.ensureDirectoryExists(dir)
        return dir
    }()
    
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
