import AppKit
import PureLayout
import UIToolz
import SwiftObserver
import SwiftyToolz

class Header: LayerBackedView, Observer
{
    // MARK: - Life Cycle
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        setItemBorder()
        backgroundColor = Color.white
        
        constrainTitleLabel()
        
        constrainIcon()
        icon.isHidden = true
    }
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
    deinit { stopAllObserving() }
    
    // MARK: - Configuration
    
    func configure(with list: SelectableList)
    {
        stopObserving(self.list?.title)
        observe(list.title)
        {
            [weak self] newTitle in
            
            self?.set(title: newTitle)
        }
        
        set(title: list.title.latestUpdate)
        showIcon(list.isRootList)
        
        if let root = list.root { update(with: root) }
        
        self.list = list
    }
    
    private weak var list: SelectableList?
    
    // MARK: - Adjust to Root State
    
    func update(with root: Task)
    {
        backgroundColor = root.backgroundColor
        
        let isUntitled = String(withNonEmpty: root.title.value) == nil
        let textColor: Color = root.isDone || isUntitled ? .grayedOut : .black
        titleLabel.textColor = textColor.nsColor
    }
    
    // MARK: - Icon
    
    func showIcon(_ show: Bool = true)
    {
        titleLabel.isHidden = show
        icon.isHidden = !show
    }
    
    private func constrainIcon()
    {
        icon.autoCenterInSuperview()
    }
    
    private lazy var icon: Icon = addForAutoLayout(Icon(with: Header.iconImage))
    
    private static let iconImage = #imageLiteral(resourceName: "home")
    
    // MARK: - Title
    
    func set(title: String?)
    {
        titleLabel.stringValue = title ?? "untitled"
        
        let textColor: Color = title == nil ? .grayedOut : .black
        titleLabel.textColor = textColor.nsColor
    }
    
    private func constrainTitleLabel()
    {
        titleLabel.autoAlignAxis(.horizontal, toSameAxisOf: self)
        titleLabel.autoPinEdge(toSuperviewEdge: .left, withInset: 10)
        titleLabel.autoPinEdge(toSuperviewEdge: .right, withInset: 10)
    }
    
    private lazy var titleLabel: Label =
    {
        let label = addForAutoLayout(Label())
        
        label.textColor = NSColor.black
        label.font = Font.text.nsFont
        label.alignment = .center
        
        return label
    }()
}
