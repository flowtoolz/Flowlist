import AppKit
import PromiseKit
import SwiftyToolz

// TODO: when moving this to UIToolz: Let AppController set this as the default Dialog, and: Properly integrate Logging / Dialog / Alerts ... Make Logging independent of SwiftObserver ...
class AlertDialog: DialogInterface
{
    func pose(_ question: Question) -> Promise<Answer>
    {
        pose(question, imageName: nil)
    }
    
    func pose(_ question: Question, imageName: String?) -> Promise<Answer>
    {
        Promise
        {
            resolver in
        
            DispatchQueue.main.async
            {
                let alert = NSAlert()
                
                alert.alertStyle = .informational
                alert.messageText = question.title
                alert.informativeText = question.text
                
                let reversedOptions: [String] = question.options.reversed()
                
                reversedOptions.forEach { alert.addButton(withTitle: $0) }
                
                if let imageName = imageName,
                    let image = NSImage(named: NSImage.Name(imageName))
                {
                    alert.icon = image
                }
                
                let response = alert.runModal()
                
                if reversedOptions.isEmpty
                {
                    resolver.fulfill(Answer(options: ["OK"]))
                    return
                }
                
                let lastButton = NSApplication.ModalResponse.alertFirstButtonReturn
                let reversedOptionIndex = response.rawValue - lastButton.rawValue
                
                guard reversedOptions.isValid(index: reversedOptionIndex) else
                {
                    let message = "Unknown modal response"
                    log(error: message)
                    return resolver.reject(ReadableError(message))
                }
                
                let clickedOption = reversedOptions[reversedOptionIndex]

                resolver.fulfill(Answer(options: [clickedOption]))
            }
        }
    }
}
