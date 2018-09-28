import AppKit
import UIToolz
import SwiftObserver
import SwiftyToolz

class Header: LayerBackedView, Observer
{
    // MARK: - Life Cycle
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        backgroundColor = .itemBackground(isDone: false,
                                          isSelected: false,
                                          isTagged: false,
                                          isFocusedList: false)
        
        icon.isHidden = true
        
        constrainLayoutGuide()
        constrainTitleLabel()
        constrainIcon()
        
        observe(darkMode)
        {
            [weak self] _ in
            
            self?.titleLabel.textColor = Color.text.nsColor
            self?.icon.image = Header.iconImage
            self?.backgroundColor = .itemBackground(isDone: false,
                                                    isSelected: false,
                                                    isTagged: false,
                                                    isFocusedList: false)
        }
        
        observe(Font.baseSize)
        {
            [weak self] _ in
            
            self?.updateLayoutConstants()
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
        
        let textColor = Color.itemText(isDone: root.isDone || isUntitled,
                                       isSelected: false,
                                       isFocused: true)
        
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
        icon.constrainCenterY(to: layoutGuide)
        icon.constrainCenterXToParent()
        icon.constrainWidth(to: 0.57, of: layoutGuide)
    }
    
    private lazy var icon = addForAutoLayout(Icon(with: Header.iconImage))
    
    private static var iconImage: NSImage
    {
        return Color.isInDarkMode ? iconImageWhite : iconImageBlack
    }
    
    private static let iconImageBlack = #imageLiteral(resourceName: "home_pdf")
    private static let iconImageWhite = #imageLiteral(resourceName: "home_white")
    
    // MARK: - Title
    
    func set(title: String?)
    {
        titleLabel.stringValue = (title ?? "untitled").replacingOccurrences(of: "\n", with: " ")
        
        let textColor = Color.itemText(isDone: title == nil,
                                       isSelected: false,
                                       isFocused: true)
        
        titleLabel.textColor = textColor.nsColor
    }
    
    private func constrainTitleLabel()
    {
        titleLabel.constrainRightToParent()
        titleLabel.constrainLeft(to: 0.3, of: layoutGuide)
        titleLabel.constrainTopToParent(at: 0.26)
    }
    
    private var titleSideInsetConstraints = [NSLayoutConstraint]()
    
    private lazy var titleLabel: Label =
    {
        let label = addForAutoLayout(Label())
        
        label.textColor = Color.text.nsColor
        label.font = Font.listTitle.nsFont
        label.alignment = .left
        label.maximumNumberOfLines = 1
        
        return label
    }()
    
    // MARK: - Layout Guide
    
    private func updateLayoutConstants()
    {
        let size = layouGuideSize
        
        for constraint in layoutGuideSizeConstraints
        {
            constraint.constant = size
        }
    }
    
    private func constrainLayoutGuide()
    {
        layoutGuide.constrainLeft(to: self)
        layoutGuide.constrainBottom(to: self)
        
        let size = layouGuideSize
        
        layoutGuideSizeConstraints = layoutGuide.constrainSize(to: size, size)
    }
    
    private var layouGuideSize: CGFloat
    {
        return TaskView.heightWithSingleLine
    }
    
    private var layoutGuideSizeConstraints = [NSLayoutConstraint]()
    
    private lazy var layoutGuide = addLayoutGuide()
}
