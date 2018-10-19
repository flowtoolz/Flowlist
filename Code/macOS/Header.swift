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
        
        constrainLayoutGuides()
        constrainTopSpacer()
        constrainTitleContainer()
        constrainColorView()
        constrainTitleLabel()
        constrainIcon()
        
        topSpacer.layer?.cornerRadius = Float.listCornerRadius.cgFloat
        
        topSpacer.backgroundColor = .listBackground
        titleContainer.backgroundColor = .listBackground
        
        icon.isHidden = true
        
        observe(darkMode)
        {
            [weak self] _ in
            
            self?.titleLabel.textColor = Color.text.nsColor
            self?.icon.image = Header.iconImage
            
            let bgColor = Color.listBackground
            
            self?.topSpacer.backgroundColor = bgColor
            self?.titleContainer.backgroundColor = bgColor
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
    
    func configure(with list: List)
    {
        // title
        
        stopObserving(self.list?.title)
        observe(list.title)
        {
            [weak self] newTitle in
            
            self?.set(title: newTitle)
            self?.updateTitleColor()
        }
        
        set(title: list.title.latestUpdate)
        
        // focus
        
        stopObserving(self.list?.isFocused)
        observe(list.isFocused)
        {
            [weak self] focusUpdate in
            
            self?.set(focused: focusUpdate.new ?? false)
        }
        
        // tag
        
        stopObserving(self.list?.tag)
        observe(list.tag)
        {
            [weak self] newTag in
            
            self?.updateColorView(with: newTag)
        }
        
        // state
        
        stopObserving(self.list?.state)
        observe(list.state)
        {
            [weak self] _ in

            self?.updateTitleColor()
        }
        
        // other
        
        showIcon(list.isRootList)
        
        self.list = list
        
        updateTitleColor()
    }
    
    // MARK: - Icon
    
    func showIcon(_ show: Bool = true)
    {
        titleLabel.isHidden = show
        icon.isHidden = !show
    }
    
    private func constrainIcon()
    {
        icon.constrainCenterXToParent()
        icon.constrainSize(to: 0.64, 0.64, of: layoutGuideLeft)
        icon.constrainCenterYToParent(at: 0.58)
    }
    
    private lazy var icon = addForAutoLayout(Icon(with: Header.iconImage))
    
    private static var iconImage: NSImage
    {
        return Color.isInDarkMode ? iconImageWhite : iconImageBlack
    }
    
    private static let iconImageBlack = #imageLiteral(resourceName: "home_pdf")
    private static let iconImageWhite = #imageLiteral(resourceName: "home_white")
    
    // MARK: - Title
    
    private func set(title: String)
    {
        var displayTitle = title.count > 0 ? title : "Untitled"
        displayTitle = displayTitle.replacingOccurrences(of: "\n", with: " ")
        titleLabel.stringValue = displayTitle
    }
    
    func updateTitleColor()
    {
        let isUntitled = String(withNonEmpty: list?.title.latestUpdate) == nil
        let isDone = list?.state.latestUpdate == .done
        
        let textColor = Color.itemText(isDone: isDone || isUntitled,
                                       isSelected: false,
                                       isFocused: true)
        
        titleLabel.textColor = textColor.nsColor
    }
    
    private func constrainTitleLabel()
    {
        titleLabel.constrain(toTheLeftOf: layoutGuideRight)
        titleLabel.constrainLeft(to: relativeTitleInset, of: layoutGuideLeft)
        titleLabel.constrainCenterYToParent(at: 0.436)
    }
    
    private lazy var titleLabel: Label =
    {
        let label = titleContainer.addForAutoLayout(Label())
        
        label.textColor = Color.text.nsColor
        label.font = Font.listTitle.nsFont
        label.alignment = .left
        label.maximumNumberOfLines = 1
        
        return label
    }()
    
    // MARK: - Color View
    
    private func set(focused: Bool)
    {
        colorView.alphaValue = focused ? 1.0 : 0.5
    }
    
    private func updateColorView(with tag: ItemData.Tag?)
    {
        if let tagValue = tag?.rawValue
        {
            colorView.backgroundColor = Color.tags[tagValue]
            colorView.isHidden = false
        }
        else
        {
            colorView.isHidden = true
        }
    }
    
    private func constrainColorView()
    {
        colorView.constrainToParentExcludingBottom()
        colorView.constrainHeight(to: 0.25, of: layoutGuideLeft)
    }
    
    private lazy var colorView: LayerBackedView =
    {
        let view = topSpacer.addForAutoLayout(LayerBackedView())
        
        view.alphaValue = 0.5
        
        return view
    }()
    
    // MARK: - Top Spacer
    
    private func constrainTopSpacer()
    {
        topSpacer.constrainToParent()
    }
    
    private lazy var topSpacer = addForAutoLayout(LayerBackedView())
    
    // MARK: - Title Container
    
    private func constrainTitleContainer()
    {
        titleContainer.constrainToParentExcludingTop()
        titleContainer.constrainTop(to: layoutGuideLeft)
    }
    
    private lazy var titleContainer = addForAutoLayout(LayerBackedView())
    
    // MARK: - Layout Guides
    
    private func updateLayoutConstants()
    {
        let size = layouGuideSize
        
        for constraint in layoutGuideSizeConstraints
        {
            constraint.constant = size
        }
    }
    
    private func constrainLayoutGuides()
    {
        let size = layouGuideSize
        
        layoutGuideSizeConstraints = layoutGuideLeft.constrainSize(to: size, size)
        layoutGuideLeft.constrainLeft(to: self)
        layoutGuideLeft.constrainBottom(to: self)
        
        layoutGuideRight.constrainHeight(to: layoutGuideLeft)
        layoutGuideRight.constrainWidth(to: relativeTitleInset,
                                        of: layoutGuideLeft)
        layoutGuideRight.constrainBottom(to: self)
        layoutGuideRight.constrainRight(to: self)
    }
    
    private let relativeTitleInset = Float.relativeTextInset.cgFloat
    
    private var layouGuideSize: CGFloat
    {
        return ItemView.heightWithSingleLine
    }
    
    private var layoutGuideSizeConstraints = [NSLayoutConstraint]()
    
    private lazy var layoutGuideLeft = addLayoutGuide()
    private lazy var layoutGuideRight = addLayoutGuide()
    
    // MARK: - List
    
    private weak var list: List?
}
