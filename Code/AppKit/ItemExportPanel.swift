import AppKit
import UIToolz
import GetLaid
import SwiftObserver
import SwiftyToolz

extension Tree where Data == ItemData
{
    func export() { ItemExportPanel().export(self) }
}

class ItemExportPanel: NSSavePanel
{
    // MARK: - Initialize
    
    override init(contentRect: NSRect,
                  styleMask style: NSWindow.StyleMask,
                  backing backingStoreType: NSWindow.BackingStoreType,
                  defer flag: Bool)
    {
        super.init(contentRect: contentRect,
                   styleMask: style,
                   backing: backingStoreType,
                   defer: flag)
        
        message = "Export Focused List as Text"
        showsHiddenFiles = false
        showsTagField = false
        canCreateDirectories = true
        allowsOtherFileTypes = false
        isExtensionHidden = false
        allowedFileTypes = [preferredFormat.fileExtension]
        
        constrainFormatSelectionView()
        
        accessoryView = formatView
    }
    
    // MARK: - Export
    
    func export(_ item: Item)
    {
        nameFieldStringValue = item.text ?? "Untitled"
        
        begin
        {
            [weak self] modalResponse in
            
            guard modalResponse == .OK else
            {
                if modalResponse != .cancel
                {
                    log(error: "Export panel closed with unexpected response. Raw value: \(modalResponse.rawValue)")
                }
                
                return
            }
            
            guard let me = self, let fileUrl = me.url else { return }
            
            let text = item.text(me.selectedFormat)
            
            do
            {
                try text.write(to: fileUrl, atomically: false, encoding: .utf8)
            }
            catch let error
            {
                let title = "Couldn't write \"\(fileUrl.lastPathComponent)\""
                
                show(alert: error.localizedDescription, title: title)
            }
        }
    }
    
    // MARK: - Select Export Format
    
    private func constrainFormatSelectionView()
    {
        formatView.translatesAutoresizingMaskIntoConstraints = false
        formatView.constrainWidth(toMinimum: 400)
        formatView.constrainHeight(toMinimum: 40)
        
        formatContainer.constrainTopToParent()
        formatContainer.constrainBottomToParent()
        formatContainer.constrainCenterXToParent()
        
        formatLabel.constrainLeftToParent(inset: 10)
        formatLabel.constrainCenterYToParent()
        
        formatMenu.constrain(toTheRightOf: formatLabel, gap: 10)
        formatMenu.constrainToParentExcludingLeft(insetTop: 10,
                                                  insetBottom: 10,
                                                  insetRight: 10)
    }
    
    private lazy var formatLabel: Label =
    {
        let label = formatContainer.addForAutoLayout(Label())
        
        label.font = .system
        label.stringValue = "Select Format:"
        label.alignment = .right
        
        return label
    }()
    
    @objc private func userDidChangeFormat()
    {
        allowedFileTypes = [selectedFormat.fileExtension]
        
        preferredFormat = selectedFormat
    }
    
    var selectedFormat: TextFormat
    {
        return TextFormat.allCases[formatMenu.indexOfSelectedItem]
    }
    
    private lazy var formatMenu: NSPopUpButton =
    {
        let menu = formatContainer.addForAutoLayout(NSPopUpButton())
        
        menu.addItems(withTitles: TextFormat.allCases.map { $0.rawValue })
        menu.selectItem(withTitle: preferredFormat.rawValue)
        menu.target = self
        menu.action = #selector(userDidChangeFormat)
        
        return menu
    }()
    
    private lazy var formatContainer = formatView.addForAutoLayout(NSView())
    
    private let formatView = NSView()
    
    // MARK: - Preferred Format
    
    private var preferredFormat: TextFormat
    {
        get
        {
            guard let formatString = UserDefaults.standard.string(forKey: preferredFormatKey) else
            {
                return .plain
            }
            
            return TextFormat(rawValue: formatString) ?? .plain
        }
        
        set
        {
            UserDefaults.standard.set(newValue.rawValue,
                                      forKey: preferredFormatKey)
        }
    }
    
    private let preferredFormatKey = "UserDefaultsKeyExportFormat"
}
