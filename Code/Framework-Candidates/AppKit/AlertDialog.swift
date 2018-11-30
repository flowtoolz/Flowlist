import AppKit
import PromiseKit
import SwiftyToolz

// TODO: when moving this to UIToolz: Let AppController set this as the default Dialog
class AlertDialog: Dialog
{
    override func pose(_ question: Question,
                       imageName: String? = nil) -> Promise<Answer>
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
        
        if reversedOptions.isEmpty { return Promise.value(Answer(options: ["OK"])) }
        
        let lastButton = NSApplication.ModalResponse.alertFirstButtonReturn
        let reversedOptionIndex = response.rawValue - lastButton.rawValue
        
        guard reversedOptions.isValid(index: reversedOptionIndex) else
        {
            return Promise(error: DialogError.custom("Unknown modal response"))
        }
        
        let clickedOption = reversedOptions[reversedOptionIndex]

        return Promise.value(Answer(options: [clickedOption]))
    }
}
