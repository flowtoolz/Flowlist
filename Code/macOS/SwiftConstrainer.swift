import AppKit

extension NSLayoutGuide: HasLayoutAnchors {}
extension NSView: HasLayoutAnchors {}

// MARK: -

extension HasLayoutAnchors
{
    // MARK: Horizontal
    
    @discardableResult
    func constrainLeft<LayoutObject: HasLayoutAnchors>(to target: LayoutObject,
                                                       offset: CGFloat = 0) -> NSLayoutConstraint
    {
        return constrain(.left, to: .left, of: target, offset: offset)
    }
    
    @discardableResult
    func constrainLeft<LayoutObject: HasLayoutAnchors>(toRightOf target: LayoutObject,
                                                       offset: CGFloat = 0) -> NSLayoutConstraint
    {
        return constrain(.left, to: .right, of: target, offset: offset)
    }
    
    @discardableResult
    func constrainRight<LayoutObject: HasLayoutAnchors>(to target: LayoutObject,
                                                        offset: CGFloat = 0) -> NSLayoutConstraint
    {
        return constrain(.right, to: .right, of: target, offset: offset)
    }
    
    @discardableResult
    func constrainRight<LayoutObject: HasLayoutAnchors>(toLeftOf target: LayoutObject,
                                                        offset: CGFloat = 0) -> NSLayoutConstraint
    {
        return constrain(.right, to: .left, of: target, offset: offset)
    }
    
    @discardableResult
    func constrain<LayoutObject: HasLayoutAnchors>(_ attribute: HorizontalAttribute,
                                                   to targetAttribute: HorizontalAttribute,
                                                   of target: LayoutObject,
                                                   offset: CGFloat = 0) -> NSLayoutConstraint
    {
        let anchor = attribute == .left ? leftAnchor : rightAnchor
        let targetAnchor = targetAttribute == .left ? target.leftAnchor : target.rightAnchor
        
        let constraint = anchor.constraint(equalTo: targetAnchor, constant: offset)
        
        constraint.isActive = true
        
        return constraint
    }
    
    // MARK: Vertical
    
    @discardableResult
    func constrainTop<LayoutObject: HasLayoutAnchors>(to target: LayoutObject,
                                                      offset: CGFloat = 0) -> NSLayoutConstraint
    {
        return constrain(.top, to: .top, of: target, offset: offset)
    }
    
    @discardableResult
    func constrainTop<LayoutObject: HasLayoutAnchors>(toBottomOf target: LayoutObject,
                                                      offset: CGFloat = 0) -> NSLayoutConstraint
    {
        return constrain(.top, to: .bottom, of: target, offset: offset)
    }
    
    @discardableResult
    func constrainBottom<LayoutObject: HasLayoutAnchors>(to target: LayoutObject,
                                                         offset: CGFloat = 0) -> NSLayoutConstraint
    {
        return constrain(.bottom, to: .bottom, of: target, offset: offset)
    }
    
    @discardableResult
    func constrainBottom<LayoutObject: HasLayoutAnchors>(toTopOf target: LayoutObject,
                                                         offset: CGFloat = 0) -> NSLayoutConstraint
    {
        return constrain(.bottom, to: .top, of: target, offset: offset)
    }
    
    @discardableResult
    func constrain<LayoutObject: HasLayoutAnchors>(_ attribute: VerticalAttribute,
                                                   to targetAttribute: VerticalAttribute,
                                                   of target: LayoutObject,
                                                   offset: CGFloat = 0) -> NSLayoutConstraint
    {
        let anchor = attribute == .top ? topAnchor : bottomAnchor
        let targetAnchor = targetAttribute == .top ? target.topAnchor : target.bottomAnchor
        
        let constraint = anchor.constraint(equalTo: targetAnchor, constant: offset)
        
        constraint.isActive = true
        
        return constraint
    }
    
    // MARK: Size
    
    @discardableResult
    func constrainWidth(toMinimum minimum: CGFloat) -> NSLayoutConstraint
    {
        let constraint = widthAnchor.constraint(greaterThanOrEqualToConstant: minimum)
        
        constraint.isActive = true
        
        return constraint
    }
    
    @discardableResult
    func constrainWidth<LayoutObject: HasLayoutAnchors>(to target: LayoutObject) -> NSLayoutConstraint
    {
        let constraint = widthAnchor.constraint(equalTo: target.widthAnchor)
        
        constraint.isActive = true
        
        return constraint
    }
}

// MARK: -

enum HorizontalAttribute { case left, right }
enum VerticalAttribute { case top, bottom }

// MARK: -

protocol HasLayoutAnchors
{
    var widthAnchor: NSLayoutDimension { get }
    var topAnchor: NSLayoutYAxisAnchor { get }
    var bottomAnchor: NSLayoutYAxisAnchor { get }
    var leftAnchor: NSLayoutXAxisAnchor { get }
    var rightAnchor: NSLayoutXAxisAnchor { get }
}
