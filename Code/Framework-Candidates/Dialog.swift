import PromiseKit

class Dialog
{
    static var `default` = Dialog()
    
    func pose(_ question: Question,
              imageName: String? = nil) -> Promise<Answer>
    {
        return Promise(error: DialogError.notImplemented)
    }
    
    struct Question
    {
        let title: String
        let text: String
        let options: [String]
    }
    
    struct Answer
    {
        let options: [String]
    }
    
    enum DialogError: Error
    {
        case notImplemented
        case custom(_ message: String)
    }
}
