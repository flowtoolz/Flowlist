import PromiseKit
import SwiftyToolz

class Dialog
{
    static var `default` = Dialog()
    
    func pose(_ question: Question, imageName: String? = nil) -> Promise<Answer>
    {
        let message = "Dialog is an abstract class that needs to be subclassed. Don't use Dialog directly as it has no implementation of \(#function)"
        log(error: message)
        return .fail(message)
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
}
