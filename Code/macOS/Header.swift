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
    }
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
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
