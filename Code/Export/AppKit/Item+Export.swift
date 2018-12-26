import AppKit
import UIToolz
import SwiftyToolz

extension Tree where Data == ItemData
{
    func export() { Exporter().export(self) }
}

class Exporter
{
    func export(_ item: Item)
    {
        panel.nameFieldStringValue = item.text ?? "Untitled"
        
        panel.begin
        {
            modalResponse in
            
            guard modalResponse == .OK else
            {
                if modalResponse != .cancel
                {
                    log(error: "Export panel closed with unexpected response. Raw value: \(modalResponse.rawValue)")
                }
                
                return
            }
            
            guard let fileUrl = self.panel.url else
            {
                log(error: "Export panel has no URL.")
                return
            }
            
            let text = item.text(self.accessoryView.selectedFormat)
            
            do
            {
                try text.write(to: fileUrl,
                               atomically: false,
                               encoding: .utf8)
            }
            catch let error
            {
                log(error: error.localizedDescription)
                
                let title = "Couldn't write \"\(fileUrl.lastPathComponent)\""
                show(alert: error.localizedDescription, title: title)
            }
        }
    }
    
    @objc private func didChangeFormat()
    {
        let newFormat = accessoryView.selectedFormat
        
        panel.allowedFileTypes = [newFormat.fileExtension]
        TextFormat.preferred = newFormat
    }
    
    private lazy var panel: NSSavePanel =
    {
        let savePanel = NSSavePanel().configureForItemExport()
        
        savePanel.accessoryView = accessoryView
        
        return savePanel
    }()
    
    private lazy var accessoryView: ExportAcessoryView =
    {
        let view = ExportAcessoryView()
        
        view.formatMenu.target = self
        view.formatMenu.action = #selector(didChangeFormat)
        
        return view
    }()
}

extension NSSavePanel
{
    func configureForItemExport() -> NSSavePanel
    {
        message = "Export Focused List as Text"
        showsHiddenFiles = false
        showsTagField = false
        canCreateDirectories = true
        allowsOtherFileTypes = false
        isExtensionHidden = false
        allowedFileTypes = [TextFormat.preferred.fileExtension]
        
        return self
    }
}
