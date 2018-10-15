import AppKit

extension Tree where Data == ItemData
{
    func export()
    {
        let panel = NSSavePanel()
        
        panel.message = "Export Focused List as Plain Text"
        panel.nameFieldStringValue = (title ?? "Untitled") + ".txt"
        panel.showsHiddenFiles = false
        panel.showsTagField = false
        panel.canCreateDirectories = true
        panel.allowsOtherFileTypes = false
        panel.isExtensionHidden = false
        panel.allowedFileTypes = ["txt"]
        
        panel.begin
        {
            [weak self] modalResponse in
            
            guard modalResponse.rawValue == NSFileHandlingPanelOKButton,
                let fileUrl = panel.url else { return }
            
            try? self?.text().write(to: fileUrl,
                                    atomically: false,
                                    encoding: .utf8)
        }
    }
}
