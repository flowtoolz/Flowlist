import AppKit
import UIToolz
import SwiftObserver

class Spacer: LayerBackedView, Observer
{
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        identifier = Spacer.uiIdentifier
        
        backgroundColor = .listBackground
        
        observe(darkMode)
        {
            [weak self] _ in self?.backgroundColor = .listBackground
        }
    }
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
    deinit { stopAllObserving() }
    
    static let uiIdentifier = NSUserInterfaceItemIdentifier(rawValue: "SpacerID")
}
