import AppKit
import UIToolz
import SwiftyToolz

class ProgressBar: LayerBackedView
{
    // MARK: - Color
    
    var progressColor: Color
    {
        set
        {
            progressIndicator.backgroundColor = newValue
        }
        
        get
        {
            return progressIndicator.backgroundColor
        }
    }
    
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
            NSAnimationContext.beginGrouping()
            
            let context = NSAnimationContext.current
            context.allowsImplicitAnimation = true
            context.duration = 0.3
            
            if let constraint = widthConstraint
            {
                removeConstraint(constraint)
                progressIndicator.removeConstraint(constraint)
            }
            
            let cappedCGFloat = max(0.0, min(1.0, newValue))

            constrainIndicator(widthFactor: cappedCGFloat)
            
            layoutSubtreeIfNeeded()
            
            NSAnimationContext.endGrouping()
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
