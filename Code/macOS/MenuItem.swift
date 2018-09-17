import AppKit
import SwiftyToolz

public class MenuItem: NSMenuItem
{
    // MARK: - Initialization
    
    init(_ title: String,
         key: String = "",
         modifiers: NSEvent.ModifierFlags = [.command],
         validator: NSObject? = nil,
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
    
    public override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
    {
        guard menuItem === self else
        {
            log(warning: "validateMenuItem(...) was called with a different NSMenuItem than self")
            return true
        }
        
        return validator?.validateMenuItem(self) ?? true
    }
    
    private weak var validator: NSObject?
}
