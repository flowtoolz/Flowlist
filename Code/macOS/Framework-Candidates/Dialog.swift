import PromiseKit
import SwiftyToolz

class Dialog
{
    static var `default`: DialogInterface?
}

protocol DialogInterface
{
    func pose(_ question: Question, imageName: String?) -> Promise<Answer>
    func pose(_ question: Question) -> Promise<Answer>
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
