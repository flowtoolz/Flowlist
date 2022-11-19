import AppKit
import SwiftyToolz

// TODO: when moving this to UIToolz: Let AppController set this as the default Dialog, and: Properly integrate Logging / Dialog / Alerts ... Make Logging independent of SwiftObserver ...
class AlertDialog: DialogInterface
{
    func pose(_ question: Question) async throws -> Answer
    {
        try await pose(question, imageName: nil)
    }
    
    func pose(_ question: Question, imageName: String?) async throws -> Answer
    {
        try await withCheckedThrowingContinuation
        {
            continuation in
        
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
                    return continuation.resume(returning: Answer(options: ["OK"]))
                }
                
                let lastButton = NSApplication.ModalResponse.alertFirstButtonReturn
                let reversedOptionIndex = response.rawValue - lastButton.rawValue
                
                guard reversedOptions.isValid(index: reversedOptionIndex) else
                {
                    return continuation.resume(throwing: "Unknown modal response")
                }
                
                let clickedOption = reversedOptions[reversedOptionIndex]

                continuation.resume(returning: Answer(options: [clickedOption]))
            }
        }
    }
}
