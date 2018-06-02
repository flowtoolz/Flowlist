import AppKit

public extension NSMenuItem
{
    convenience init(with menu: NSMenu)
    {
        self.init()
        
        submenu = menu
    }
}
