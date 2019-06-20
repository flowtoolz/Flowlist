import XCTest
@testable import Flowlist
import CloudKit

class CKRecordSystemFieldsCacheTests: XCTestCase
{
    func testThatCKRecordsCanBeSavedToCacheFolder()
    {
        let data = ItemData(id: "Test Item ID")
        let item = Item(data: data)
        let record = Record(item: item)
        let ckRecord = CKRecord(record: record)
        
        let urlOfSavedFile = CKRecordSystemFieldsCache().save(ckRecord)
        XCTAssertNotNil(urlOfSavedFile)
    }
    
    func testThatCKRecordsCanBeLoadedFromCacheFolder()
    {
        let id = "Test Item ID"
        let data = ItemData(id: id)
        let item = Item(data: data)
        let record = Record(item: item)
        let ckRecord = CKRecord(record: record)
        CKRecordSystemFieldsCache().save(ckRecord)
        
        let loadedCKRecord = CKRecordSystemFieldsCache().loadCKRecord(with: id)
        XCTAssertNotNil(loadedCKRecord)
    }
    
    override func setUp()
    {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown()
    {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
}
