import SwiftObserver
import SwiftyToolz

class Dialog
{
    static var `default`: DialogInterface?
}

protocol DialogInterface
{
    func pose(_ question: Question, imageName: String?) -> ResultPromise<Answer>
    func pose(_ question: Question) -> ResultPromise<Answer>
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
