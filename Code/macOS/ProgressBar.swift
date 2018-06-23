import AppKit
import UIToolz
import SwiftyToolz

class ProgressBar: LayerBackedView
{
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        backgroundColor = Color(1.0, 0.0, 0.0)
        
        constrainProgressIndicator()
    }
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
    // MARK: - Progress Indicator
    
    var progress: CGFloat
    {
        set
        {
            // TODO: animate the shit outa this!
            
            if let constraint = widthConstraint
            {
                removeConstraint(constraint)
                progressIndicator.removeConstraint(constraint)
            }
            
            let cappedCGFloat = max(0.0, min(1.0, newValue))

            constrainIndicator(widthFactor: cappedCGFloat)
        }
        
        get { return widthConstraint?.multiplier ?? 0 }
    }
    
    private func constrainProgressIndicator(with widthFactor: CGFloat = 0)
    {
        progressIndicator.autoPinEdgesToSuperviewEdges(with: NSEdgeInsetsZero,
                                                       excludingEdge: .right)
        
        constrainIndicator(widthFactor: widthFactor)
    }
    
    private func constrainIndicator(widthFactor: CGFloat)
    {
        widthConstraint = progressIndicator.autoMatch(.width,
                                                      to: .width,
                                                      of: self,
                                                      withMultiplier: widthFactor)
    }
    
    private var widthConstraint: NSLayoutConstraint?
    
    private lazy var progressIndicator: LayerBackedView =
    {
        let view = addForAutoLayout(LayerBackedView())
        
        view.backgroundColor = Color(0.0, 1.0, 0.0)
        
        return view
    }()
}
