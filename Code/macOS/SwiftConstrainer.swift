import AppKit

extension NSLayoutGuide: LayoutItem {}
extension NSView: LayoutItem {}

// MARK: -

extension LayoutItem
{
    // MARK: Position
    
    @discardableResult
    func constrainCenter<Target: LayoutItem>(to target: Target) -> [NSLayoutConstraint]
    {
        return [constrainCenterX(to: target), constrainCenterY(to: target)]
    }
    
    // MARK: Horizontal Position
    
    @discardableResult
    func constrainLeft<Target: LayoutItem>(to target: Target,
                                           offset: CGFloat = 0) -> NSLayoutConstraint
    {
        return constrain(.left, to: .left, of: target, offset: offset)
    }
    
    @discardableResult
    func constrainLeft<Target: LayoutItem>(toRightOf target: Target,
                                           offset: CGFloat = 0) -> NSLayoutConstraint
    {
        return constrain(.left, to: .right, of: target, offset: offset)
    }
    
    @discardableResult
    func constrainRight<Target: LayoutItem>(to target: Target,
                                            offset: CGFloat = 0) -> NSLayoutConstraint
    {
        return constrain(.right, to: .right, of: target, offset: offset)
    }
    
    @discardableResult
    func constrainRight<Target: LayoutItem>(toLeftOf target: Target,
                                            offset: CGFloat = 0) -> NSLayoutConstraint
    {
        return constrain(.right, to: .left, of: target, offset: offset)
    }
    
    @discardableResult
    func constrainCenterX<Target: LayoutItem>(to target: Target,
                                              offset: CGFloat = 0) -> NSLayoutConstraint
    {
        return constrain(.centerX, to: .centerX, of: target, offset: offset)
    }
    
    @discardableResult
    private func constrain<Target: LayoutItem>(_ position: XPosition,
                                               to targetPosition: XPosition,
                                               of target: Target,
                                               offset: CGFloat = 0) -> NSLayoutConstraint
    {
        let myAnchor = anchor(for: position)
        let targetAnchor = target.anchor(for: targetPosition)
        
        let constraint = myAnchor.constraint(equalTo: targetAnchor, constant: offset)
        
        constraint.isActive = true
        
        return constraint
    }
    
    private func anchor(for xPosition: XPosition) -> NSLayoutXAxisAnchor
    {
        switch xPosition
        {
        case .left: return leftAnchor
        case .centerX: return centerXAnchor
        case .right: return rightAnchor
        }
    }
    
    @discardableResult
    func constrainLeft<Target: LayoutItem>(to relativePosition: CGFloat,
                                           of target: Target) -> NSLayoutConstraint
    {
        let constraint = NSLayoutConstraint(item: self,
                                            attribute: .left,
                                            relatedBy: .equal,
                                            toItem: target,
                                            attribute: .right,
                                            multiplier: relativePosition,
                                            constant: 0)
        
        constraint.isActive = true
        
        return constraint
    }
    
    // MARK: Vertical Position
    
    @discardableResult
    func constrainTop<Target: LayoutItem>(to target: Target,
                                          offset: CGFloat = 0) -> NSLayoutConstraint
    {
        return constrain(.top, to: .top, of: target, offset: offset)
    }
    
    @discardableResult
    func constrainTop<Target: LayoutItem>(toBottomOf target: Target,
                                          offset: CGFloat = 0) -> NSLayoutConstraint
    {
        return constrain(.top, to: .bottom, of: target, offset: offset)
    }
    
    @discardableResult
    func constrainBottom<Target: LayoutItem>(to target: Target,
                                             offset: CGFloat = 0) -> NSLayoutConstraint
    {
        return constrain(.bottom, to: .bottom, of: target, offset: offset)
    }
    
    @discardableResult
    func constrainBottom<Target: LayoutItem>(toTopOf target: Target,
                                             offset: CGFloat = 0) -> NSLayoutConstraint
    {
        return constrain(.bottom, to: .top, of: target, offset: offset)
    }
    
    @discardableResult
    func constrainCenterY<Target: LayoutItem>(to target: Target,
                                              offset: CGFloat = 0) -> NSLayoutConstraint
    {
        return constrain(.centerY, to: .centerY, of: target, offset: offset)
    }
    
    @discardableResult
    private func constrain<Target: LayoutItem>(_ position: YPosition,
                                               to targetPosition: YPosition,
                                               of target: Target,
                                               offset: CGFloat = 0) -> NSLayoutConstraint
    {
        let myAnchor = anchor(for: position)
        let targetAnchor = target.anchor(for: targetPosition)
        
        let constraint = myAnchor.constraint(equalTo: targetAnchor, constant: offset)
        
        constraint.isActive = true
        
        return constraint
    }
    
    private func anchor(for yPosition: YPosition) -> NSLayoutYAxisAnchor
    {
        switch yPosition
        {
        case .top: return topAnchor
        case .centerY: return centerYAnchor
        case .bottom: return bottomAnchor
        }
    }
    
    @discardableResult
    func constrainTop<Target: LayoutItem>(to relativePosition: CGFloat,
                                          of target: Target) -> NSLayoutConstraint
    {
        let constraint = NSLayoutConstraint(item: self,
                                            attribute: .top,
                                            relatedBy: .equal,
                                            toItem: target,
                                            attribute: .bottom,
                                            multiplier: relativePosition,
                                            constant: 0)
        
        constraint.isActive = true
        
        return constraint
    }
    
    // MARK: Width
    
    @discardableResult
    func constrainWidth(to width: CGFloat) -> NSLayoutConstraint
    {
        return constrain(.width, to: width)
    }
    
    @discardableResult
    func constrainWidth(toMinimum minimum: CGFloat) -> NSLayoutConstraint
    {
        return constrain(.width, toMinimum: minimum)
    }

    @discardableResult
    func constrainWidth<Target: LayoutItem>(to target: Target) -> NSLayoutConstraint
    {
        return constrain(.width, to: target)
    }
    
    @discardableResult
    func constrainWidth<Target: LayoutItem>(to relativeSize: CGFloat,
                                            of target: Target) -> NSLayoutConstraint
    {
        return constrain(.width, to: relativeSize, of: target)
    }
    
    // MARK: Height
    
    @discardableResult
    func constrainHeight(to height: CGFloat) -> NSLayoutConstraint
    {
        return constrain(.height, to: height)
    }
    
    @discardableResult
    func constrainHeight(toMinimum minimum: CGFloat) -> NSLayoutConstraint
    {
        return constrain(.height, toMinimum: minimum)
    }
    
    @discardableResult
    func constrainHeight<Target: LayoutItem>(to target: Target) -> NSLayoutConstraint
    {
        return constrain(.height, to: target)
    }
    
    @discardableResult
    func constrainHeight<Target: LayoutItem>(to relativeSize: CGFloat,
                                             of target: Target) -> NSLayoutConstraint
    {
        return constrain(.height, to: relativeSize, of: target)
    }
    
    // MARK: Size
    
    @discardableResult
    private func constrain(_ dimension: Dimension,
                           to size: CGFloat) -> NSLayoutConstraint
    {
        let myAnchor = anchor(for: dimension)
        
        let constraint = myAnchor.constraint(equalToConstant: size)
        
        constraint.isActive = true
        
        return constraint
    }
    
    @discardableResult
    private func constrain(_ dimension: Dimension,
                           toMinimum minimum: CGFloat) -> NSLayoutConstraint
    {
        let myAnchor = anchor(for: dimension)
        
        let constraint = myAnchor.constraint(greaterThanOrEqualToConstant: minimum)
        
        constraint.isActive = true
        
        return constraint
    }
    
    @discardableResult
    private func constrain<Target: LayoutItem>(_ dimension: Dimension,
                                               to target: Target) -> NSLayoutConstraint
    {
        let myAnchor = anchor(for: dimension)
        let targetAnchor = target.anchor(for: dimension)
        
        let constraint = myAnchor.constraint(equalTo: targetAnchor)
        
        constraint.isActive = true
        
        return constraint
    }
    
    private func anchor(for dimension: Dimension) -> NSLayoutDimension
    {
        return dimension == .width ? widthAnchor : heightAnchor
    }
    
    @discardableResult
    private func constrain<Target: LayoutItem>(_ dimension: Dimension,
                                               to relativeSize: CGFloat,
                                               of target: Target) -> NSLayoutConstraint
    {
        let attribute = dimension.attribute
        
        let constraint = NSLayoutConstraint(item: self,
                                            attribute: attribute,
                                            relatedBy: .equal,
                                            toItem: target,
                                            attribute: attribute,
                                            multiplier: relativeSize,
                                            constant: 0)
        
        constraint.isActive = true
        
        return constraint
    }
}

// MARK: -

enum XPosition { case left, centerX, right }
enum YPosition { case top, centerY, bottom }

enum Dimension
{
    case width, height
    
    var attribute: NSLayoutConstraint.Attribute
    {
        return self == .width ? .width : .height
    }
}

// MARK: -

protocol LayoutItem
{
    var widthAnchor: NSLayoutDimension { get }
    var heightAnchor: NSLayoutDimension { get }
    
    var leftAnchor: NSLayoutXAxisAnchor { get }
    var centerXAnchor: NSLayoutXAxisAnchor { get }
    var rightAnchor: NSLayoutXAxisAnchor { get }
    
    var topAnchor: NSLayoutYAxisAnchor { get }
    var centerYAnchor: NSLayoutYAxisAnchor { get }
    var bottomAnchor: NSLayoutYAxisAnchor { get }

}
