import AppKit

class EditMenu: NSMenu
{
    // MARK: - Initialization
    
    init()
    {
        super.init(title: "Edit")
        
        addItem(item("Add on Top",
                     action: #selector(doNothingHere),
                     key: " ",
                     modifiers: []))
        addItem(item("Add",
                     action: #selector(doNothingHere),
                     key: "\n",
                     modifiers: []))
        addItem(item("Rename / Group",
                     action: #selector(doNothingHere),
                     key: "\n"))
        addItem(item("Check Off",
                     action: #selector(doNothingHere),
                     key: String(unicode: NSBackspaceCharacter)))
        
        addItem(NSMenuItem.separator())
        
        addItem(item("Move Up",
                     action: #selector(doNothingHere),
                     key: String(unicode: NSUpArrowFunctionKey)))
        addItem(item("Move Down",
                     action: #selector(doNothingHere),
                     key: String(unicode: NSDownArrowFunctionKey)))
        
        addItem(NSMenuItem.separator())
        
        addItem(item("Copy", action: #selector(doNothingHere), key: "c"))
        addItem(item("Cut", action: #selector(doNothingHere), key: "x"))
        addItem(item("Paste", action: #selector(doNothingHere), key: "v"))
        
        addItem(NSMenuItem.separator())
        
        addItem(item("Delete",
                     action: #selector(doNothingHere),
                     key: String(unicode: NSBackspaceCharacter),
                     modifiers: []))
        addItem(item("Paste Deleted Tasks",
                     action: #selector(doNothingHere),
                     key: "z"))
    }
    
    required init(coder decoder: NSCoder) { fatalError() }
    
    // MARK: - Dummy Function
    
    @objc private func doNothingHere() { }
}

extension String
{
    init(unicode: Int)
    {
        var unicharacter = unichar(unicode)
        
        self = String(utf16CodeUnits: &unicharacter, count: 1)
    }
}
