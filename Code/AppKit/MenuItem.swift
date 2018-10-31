import AppKit
import SwiftObserver

public class MenuItem: NSMenuItem, NSMenuItemValidation
{
    // MARK: - Initialization
    
    convenience init(_ title: String,
                     key: NSEvent.SpecialKey,
                     modifiers: NSEvent.ModifierFlags = [.command],
                     validator: NSMenuItemValidation? = nil,
                     action: @escaping () -> Void)
    {
        self.init(title,
                  key: String(key.unicodeScalar),
                  modifiers: modifiers,
                  validator: validator,
                  action: action)
    }
    
    init(_ title: String,
         key: String = "",
         modifiers: NSEvent.ModifierFlags = [.command],
         validator: NSMenuItemValidation? = nil,
         action: @escaping () -> Void)
    {
        actionClosure = action

        super.init(title: title,
                   action: #selector(performAction),
                   keyEquivalent: key)
        
        target = self
        self.validator = validator

        keyEquivalentModifierMask = modifiers
    }
    
    required public init(coder decoder: NSCoder) { fatalError() }
    
    // MARK: - Action Closure
    
    @objc func performAction() { actionClosure() }
        
    private let actionClosure: () -> Void
    
    // MARK: - Validation
    
    public func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
    {
        guard menuItem === self else
        {
            log(warning: "validateMenuItem(...) was called with a different NSMenuItem than self")
            return true
        }
        
        return validator?.validateMenuItem(self) ?? true
    }
    
    private weak var validator: NSMenuItemValidation?
}
