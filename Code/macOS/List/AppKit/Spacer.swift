import AppKit
import SwiftUIToolz
import GetLaid
import SwiftObserver
import SwiftyToolz

class Spacer: LayerBackedView, Observer
{
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        identifier = Spacer.uiIdentifier
        
        roundCorners.layer?.cornerRadius = Double.listCornerRadius
        roundCorners.set(backgroundColor: .listBackground)
        roundCorners >> self
        
        pointyCorners.set(backgroundColor: .listBackground)
        pointyCorners >> allButBottom
        pointyCorners >> height.at(0.5)
        
        observe(Color.darkMode)
        {
            [weak self] _ in
            
            self?.roundCorners.set(backgroundColor: .listBackground)
            self?.pointyCorners.set(backgroundColor: .listBackground)
        }
    }
    
    private lazy var roundCorners = addForAutoLayout(LayerBackedView())
    private lazy var pointyCorners = addForAutoLayout(LayerBackedView())
    
    required init?(coder decoder: NSCoder) { nil }
    
    static let uiIdentifier = UIItemID(rawValue: "SpacerID")
    
    // MARK: - Observer
    
    let receiver = Receiver()
}
