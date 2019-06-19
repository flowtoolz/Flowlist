import CloudKit
import PromiseKit
import SwiftyToolz

extension CKDatabase
{
    func createSubscription(withID id: String) -> Promise<CKSubscription>
    {
        let sub = CKDatabaseSubscription(subscriptionID: CKSubscription.ID(id))
        
        return save(sub)
    }
    
    private func save(_ subscription: CKSubscription,
                      desiredKeys: [CKRecord.FieldKey]? = nil) -> Promise<CKSubscription>
    {
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.desiredKeys = desiredKeys
        
        subscription.notificationInfo = notificationInfo
        
        return Promise
        {
            resolver in
            
            // TODO: use CKModifySubscriptionsOperation instead
            
            save(subscription)
            {
                subscription, error in
                
                if let error = error
                {
                    log(error: error.ckReadable.message)
                }
                
                resolver.resolve(subscription, error?.ckReadable)
            }
        }
    }
}
