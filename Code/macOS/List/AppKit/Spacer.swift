import AppKit
import UIToolz
import SwiftObserver

class Spacer: LayerBackedView, Observer
{
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        identifier = Spacer.uiIdentifier
        
        roundCorners.layer?.cornerRadius = Float.listCornerRadius.cgFloat
        roundCorners.backgroundColor = .listBackground
        roundCorners.constrainToParent()
        
        pointyCorners.backgroundColor = .listBackground
        pointyCorners.constrainToParentExcludingBottom()
        pointyCorners.constrainHeightToParent(with: 0.5)
        
        observe(darkMode)
        {
            [weak self] _ in
            
            self?.roundCorners.backgroundColor = .listBackground
            self?.pointyCorners.backgroundColor = .listBackground
        }
    }
    
    private lazy var roundCorners = addForAutoLayout(LayerBackedView())
    private lazy var pointyCorners = addForAutoLayout(LayerBackedView())
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
    deinit { stopObserving() }
    
    static let uiIdentifier = UIItemID(rawValue: "SpacerID")
}
