import AppKit
import UIToolz
import GetLaid
import SwiftObserver
import SwiftyToolz

class Spacer: LayerBackedView, Observer
{
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        identifier = Spacer.uiIdentifier
        
        roundCorners.layer?.cornerRadius = Float.listCornerRadius.cgFloat
        roundCorners.backgroundColor = .listBackground
        roundCorners >> self
        
        pointyCorners.backgroundColor = .listBackground
        pointyCorners >> allButBottom
        pointyCorners >> height.at(0.5)
        
        observe(Color.darkMode)
        {
            [weak self] _ in
            
            self?.roundCorners.backgroundColor = .listBackground
            self?.pointyCorners.backgroundColor = .listBackground
        }
    }
    
    private lazy var roundCorners = addForAutoLayout(LayerBackedView())
    private lazy var pointyCorners = addForAutoLayout(LayerBackedView())
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
    static let uiIdentifier = UIItemID(rawValue: "SpacerID")
    
    // MARK: - Observer
    
    let receiver = Receiver()
}
