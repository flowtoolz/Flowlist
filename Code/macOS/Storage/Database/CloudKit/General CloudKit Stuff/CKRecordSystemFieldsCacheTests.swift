import XCTest
@testable import Flowlist
import CloudKit

class CKRecordSystemFieldsCacheTests: XCTestCase
{
    func testThatCKRecordsCanBeSavedToCacheFolder()
    {
        let id = "\(#function)"
        let data = ItemData(id: id)
        let item = Item(data: data)
        let record = Record(item: item)
        let ckRecord = CKRecord(record: record)
        
        let urlOfSavedFile = cache.save(ckRecord)
        XCTAssertNotNil(urlOfSavedFile)
    }
    
    func testThatCKRecordsCanBeLoadedFromCacheFolder()
    {
        let id = "\(#function)"
        let data = ItemData(id: id)
        let item = Item(data: data)
        let record = Record(item: item)
        let ckRecord = CKRecord(record: record)
        cache.save(ckRecord)
        
        let loadedCKRecord = cache.loadCKRecord(with: id)
        XCTAssertNotNil(loadedCKRecord)
    }
    
    func testThatRetrievingUncachedRecordCreatesANewOne()
    {
        let id = "\(#function)"
        
        guard let file = cache.directory?.appendingPathComponent(id) else
        {
            return XCTFail("Couldn't get cache directory URL")
        }
        
        try? FileManager.default.removeItem(at: file)
        
        XCTAssertNil(cache.loadCKRecord(with: id))
        
        let newRecord = cache.getCKRecord(with: id,
                                          type: CKRecord.itemType,
                                          zoneID: .item)
        
        XCTAssertEqual(newRecord.recordID.recordName, id)
        XCTAssertNotNil(cache.loadCKRecord(with: id))
    }
    
    override func setUp()
    {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown()
    {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // TODO: parameterize cache with name (will be folder name), record type and zone id ... then use a dedicated cache for testing ... then clean the test folder before and after this test suite (in the static funcs...)
    // cache.clean()
    private let cache = CKRecordSystemFieldsCache()
}
