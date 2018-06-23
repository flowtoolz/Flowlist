import AppKit
import UIToolz
import SwiftyToolz

class ProgressBar: LayerBackedView
{
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        backgroundColor = Color(1.0, 0.8, 0.8)
    }
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
    // MARK: - Progress Indicator
    
    var progress: Float
    {
        set
        {
            // TODO: animate the sit outa this!
            
            if let constraint = indicatorWidthConstraint
            {
                removeConstraint(constraint)
            }
            
            let cappedCGFloat = CGFloat(min(0.0, max(1.0, newValue)))
            
            constrainProgressIndicatorWidth(with: cappedCGFloat)
        }
        
        get
        {
            return Float(indicatorWidthConstraint?.multiplier ?? 0)
        }
    }
    
    private func constrainProgressIndicator()
    {
        progressIndicator.autoPinEdgesToSuperviewEdges(with: NSEdgeInsetsZero,
                                                       excludingEdge: .right)
        
        constrainProgressIndicatorWidth(with: 0.5)
    }
    
    private func constrainProgressIndicatorWidth(with multiplier: CGFloat)
    {
        indicatorWidthConstraint = progressIndicator.autoMatch(.width,
                                                               to: .width,
                                                               of: self,
                                                               withMultiplier: multiplier)
    }
    
    private var indicatorWidthConstraint: NSLayoutConstraint?
    
    private lazy var progressIndicator: LayerBackedView =
    {
        let view = addForAutoLayout(LayerBackedView())
        
        view.backgroundColor = Color(0.8, 1.0, 0.8)
        
        return view
    }()
}
