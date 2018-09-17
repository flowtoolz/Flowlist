import AppKit

public class MenuItem: NSMenuItem
{
    // MARK: - Initialization
    
    init(_ title: String,
         key: String = "",
         modifiers: NSEvent.ModifierFlags = [.command],
         action: @escaping () -> Void)
    {
        actionClosure = action
        
        super.init(title: title,
                   action: #selector(performAction),
                   keyEquivalent: key)
        
        target = self

        keyEquivalentModifierMask = modifiers
    }
    
    required public init(coder decoder: NSCoder) { fatalError() }
    
    // MARK: - Action Closure
    
    @objc private func performAction() { actionClosure() }
    
    private let actionClosure: () -> Void
}
