import AppKit

extension NSLayoutGuide: LayoutItem {}
extension NSView: LayoutItem {}

// MARK: -

extension LayoutItem
{
    // MARK: Horizontal
    
    @discardableResult
    func constrainLeft<LayoutObject: LayoutItem>(to target: LayoutObject,
                                                       offset: CGFloat = 0) -> NSLayoutConstraint
    {
        return constrain(.left, to: .left, of: target, offset: offset)
    }
    
    @discardableResult
    func constrainLeft<LayoutObject: LayoutItem>(toRightOf target: LayoutObject,
                                                       offset: CGFloat = 0) -> NSLayoutConstraint
    {
        return constrain(.left, to: .right, of: target, offset: offset)
    }
    
    @discardableResult
    func constrainRight<LayoutObject: LayoutItem>(to target: LayoutObject,
                                                        offset: CGFloat = 0) -> NSLayoutConstraint
    {
        return constrain(.right, to: .right, of: target, offset: offset)
    }
    
    @discardableResult
    func constrainRight<LayoutObject: LayoutItem>(toLeftOf target: LayoutObject,
                                                        offset: CGFloat = 0) -> NSLayoutConstraint
    {
        return constrain(.right, to: .left, of: target, offset: offset)
    }
    
    @discardableResult
    func constrain<LayoutObject: LayoutItem>(_ attribute: XPosition,
                                                   to targetAttribute: XPosition,
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
    func constrainTop<LayoutObject: LayoutItem>(to target: LayoutObject,
                                                      offset: CGFloat = 0) -> NSLayoutConstraint
    {
        return constrain(.top, to: .top, of: target, offset: offset)
    }
    
    @discardableResult
    func constrainTop<LayoutObject: LayoutItem>(toBottomOf target: LayoutObject,
                                                      offset: CGFloat = 0) -> NSLayoutConstraint
    {
        return constrain(.top, to: .bottom, of: target, offset: offset)
    }
    
    @discardableResult
    func constrainBottom<LayoutObject: LayoutItem>(to target: LayoutObject,
                                                         offset: CGFloat = 0) -> NSLayoutConstraint
    {
        return constrain(.bottom, to: .bottom, of: target, offset: offset)
    }
    
    @discardableResult
    func constrainBottom<LayoutObject: LayoutItem>(toTopOf target: LayoutObject,
                                                         offset: CGFloat = 0) -> NSLayoutConstraint
    {
        return constrain(.bottom, to: .top, of: target, offset: offset)
    }
    
    @discardableResult
    func constrain<LayoutObject: LayoutItem>(_ attribute: YPosition,
                                                   to targetAttribute: YPosition,
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
    func constrainWidth<LayoutObject: LayoutItem>(to target: LayoutObject) -> NSLayoutConstraint
    {
        let constraint = widthAnchor.constraint(equalTo: target.widthAnchor)
        
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
