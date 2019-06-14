import CloudKit
import SwiftObserver
import SwiftyToolz

extension Record
{
    init(ckRecord: CKRecord)
    {
        self.init(id: ckRecord.recordID.recordName,
                  text: ckRecord.text,
                  state: ckRecord.state,
                  tag: ckRecord.tag,
                  rootID: ckRecord.superItem,
                  position: ckRecord.position ?? 0)
    }
}
