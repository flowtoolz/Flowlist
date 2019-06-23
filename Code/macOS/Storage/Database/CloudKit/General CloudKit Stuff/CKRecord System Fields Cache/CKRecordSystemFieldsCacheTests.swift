import XCTest
@testable import Flowlist
import CloudKit

class CKRecordSystemFieldsCacheTests: XCTestCase
{
    func testThatCKRecordsCanBeSavedToCacheFolder()
    {
        let id = "\(#function)"
        
        removeCachedFile(with: id)
        
        let data = ItemData(id: id)
        let item = Item(data: data)
        let record = Record(item: item)
        let ckRecord = CKRecord(recordType: .item,
                                recordID: CKRecord.ID(recordName: id,
                                                      zoneID: .item))
        
        guard let savedFile = cache.save(ckRecord) else
        {
            return XCTFail("Couldn't save record to cache")
        }
        
        XCTAssert(FileManager.default.fileExists(atPath: savedFile.path))
    }
    
    func testThatRetrievingUncachedRecordCreatesANewOne()
    {
        let id = "\(#function)"
        
        guard let file = removeCachedFile(with: id) else
        {
            return XCTFail("Couldn't get file URL")
        }
        
        let newRecord = cache.getCKRecord(with: id,
                                          type: .item,
                                          zoneID: .item)
        
        XCTAssertEqual(newRecord.recordID.recordName, id)
        XCTAssert(FileManager.default.fileExists(atPath: file.path))
    }
    
    @discardableResult
    private func removeCachedFile(with id: String) -> URL?
    {
        guard let file = cache.directory?.appendingPathComponent(id) else
        {
            return nil
        }
        
        try? FileManager.default.removeItem(at: file)
        XCTAssert(!FileManager.default.fileExists(atPath: file.path))
        
        return file
    }
    
    // MARK: - The Cache Being Tested
    
    private let cache = CKRecordSystemFieldsCache(name: "iCloud Cache Test")
}
