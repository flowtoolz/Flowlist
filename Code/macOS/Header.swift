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
        
        backgroundColor = .clear
        constrainTitleLabel()
        
        constrainIcon()
        icon.isHidden = true
        
        observe(Font.baseSize)
        {
            [weak self] _ in
            
            self?.updateTitleInsets()
            self?.titleLabel.font = Font.listTitle.nsFont
        }
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
        icon.constrainHeight(to: 0.557, of: self)
        icon.constrainCenter(to: self)
    }
    
    private lazy var icon: Icon = addForAutoLayout(Icon(with: Header.iconImage))
    private static let iconImage = #imageLiteral(resourceName: "home_pdf")
    
    // MARK: - Title
    
    func set(title: String?)
    {
        titleLabel.stringValue = (title ?? "untitled").replacingOccurrences(of: "\n", with: " ")
        
        let textColor: Color = title == nil ? .grayedOut : .black
        titleLabel.textColor = textColor.nsColor
    }
    
    private func constrainTitleLabel()
    {
        let inset = titleSideInset

        titleSideInsetConstraints =
        [
            titleLabel.constrainLeft(to:self, offset: inset),
            titleLabel.constrainRight(to: self, offset: -inset)
        ]
        
        titleLabel.constrainTop(to: 0.26, of: self)
    }
    
    private func updateTitleInsets()
    {
        let inset = titleSideInset
        
        for constraint in titleSideInsetConstraints
        {
            constraint.constant = constraint.constant < 0 ? -inset : inset
        }
    }
    
    private var titleSideInset: CGFloat
    {
        return TaskView.spacing + TaskView.padding - 2
    }
    
    private var titleSideInsetConstraints = [NSLayoutConstraint]()
    
    private lazy var titleLabel: Label =
    {
        let label = addForAutoLayout(Label())
        
        label.textColor = NSColor.black
        label.font = Font.listTitle.nsFont
        label.alignment = .center
        label.maximumNumberOfLines = 1
        
        return label
    }()
}
