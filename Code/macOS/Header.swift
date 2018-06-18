import AppKit
import PureLayout
import UIToolz
import SwiftyToolz

class Header: LayerBackedView
{
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        setItemBorder()
        
        backgroundColor = Color.white
        
        constrainTitleField()
        constrainIcon()
    }
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
    // MARK: - Adjust to Root State
    
    func update(with root: Task)
    {
        backgroundColor = root.backgroundColor
        
        let textColor: Color = root.isDone ? .grayedOut : .black
        titleField.textColor = textColor.nsColor
    }
    
    // MARK: - Icon
    
    func showIcon(_ show: Bool = true)
    {
        titleField.isHidden = show
        icon.isHidden = !show
    }
    
    private func constrainIcon()
    {
        icon.autoCenterInSuperview()
    }
    
    private lazy var icon: NSImageView =
    {
        let view = addForAutoLayout(NSImageView())
        
        view.image = Header.iconImage
        view.imageScaling = .scaleNone
        view.imageAlignment = .alignCenter
        view.isHidden = true
        
        return view
    }()
    
    private static let iconImage = #imageLiteral(resourceName: "home")
    
    // MARK: - Title
    
    func set(title: String?)
    {
        titleField.stringValue = title ?? "untitled"
        
        let textColor: Color = title == nil ? .grayedOut : .black
        titleField.textColor = textColor.nsColor
    }
    
    private func constrainTitleField()
    {
        titleField.autoAlignAxis(.horizontal, toSameAxisOf: self)
        titleField.autoPinEdge(toSuperviewEdge: .left, withInset: 10)
        titleField.autoPinEdge(toSuperviewEdge: .right, withInset: 10)
    }
    
    private lazy var titleField: NSTextField =
    {
        let field = addForAutoLayout(NSTextField())
        
        field.textColor = NSColor.black
        field.font = Font.text.nsFont
        
        let priority = NSLayoutConstraint.Priority(rawValue: 0.1)
        field.setContentCompressionResistancePriority(priority, for: .horizontal)
        
        field.lineBreakMode = .byTruncatingTail
        field.drawsBackground = false
        field.alignment = .center
        field.isEditable = false
        field.isBezeled = false
        field.isBordered = false
        field.isSelectable = false
        
        return field
    }()
}
