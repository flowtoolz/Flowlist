import AppKit

class EditMenu: NSMenu
{
    // MARK: - Initialization
    
    init()
    {
        super.init(title: "Edit")
        
        addItem(item("Copy", action: #selector(doNothingHere), key: "c"))
        addItem(item("Cut", action: #selector(doNothingHere), key: "x"))
        addItem(item("Paste", action: #selector(doNothingHere), key: "v"))
    }
    
    required init(coder decoder: NSCoder) { fatalError() }
    
    // MARK: - Dummy Function
    
    @objc private func doNothingHere() { }
}
