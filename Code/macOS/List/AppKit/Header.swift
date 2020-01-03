import AppKit
import UIToolz
import GetLaid
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
        
        observe(Color.darkMode)
        {
            [weak self] _ in
            
            self?.updateTitleColor()
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
    
    // MARK: - Configuration
    
    func configure(with list: List)
    {
        // title
        
        stopObserving(self.list?.title)
        observe(list.title).new().unwrap("")
        {
            [weak self] newTitle in
            
            self?.set(title: newTitle)
            self?.updateTitleColor()
        }
        
        set(title: list.title.value ?? "")
        
        // focus
        
        stopObserving(self.list?.isFocused)
        observe(list.isFocused)
        {
            [weak self] focusUpdate in
            
            self?.set(focused: focusUpdate.new)
        }
        
        // tag
        
        stopObserving(self.list?.tag)
        observe(list.tag).new()
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
        
        showIcon(if: list.isRootList)
        
        self.list = list
        
        updateTitleColor()
    }
    
    // MARK: - Icon
    
    private func showIcon(if show: Bool = true)
    {
        titleLabel.isHidden = show
        icon.isHidden = !show
    }
    
    private func constrainIcon()
    {
        icon.constrainToParentCenterX()
        icon.constrain(to: layoutGuideLeft.size.at(0.64))
        icon.constrainCenterYToParent(at: 0.58)
    }
    
    private lazy var icon = addForAutoLayout(Icon(with: Header.iconImage))
    
    private static var iconImage: NSImage
    {
        Color.isInDarkMode ? iconImageWhite : iconImageBlack
    }
    
    private static let iconImageBlack = #imageLiteral(resourceName: "home_pdf")
    private static let iconImageWhite = #imageLiteral(resourceName: "home_white")
    
    // MARK: - Title
    
    private func set(title: String)
    {
        let nonEmptyTitle = String(withNonEmpty: title)
        isUntitled = nonEmptyTitle == nil
        
        var displayTitle = nonEmptyTitle ?? Header.untitled
        displayTitle = displayTitle.replacingOccurrences(of: "\n", with: " ")
        titleLabel.stringValue = displayTitle
    }
    
    private func updateTitleColor()
    {
        let isDone = list?.state.value == .done
        
        let textColor = Color.itemText(isDone: isDone || isUntitled,
                                       isSelected: false,
                                       isFocused: true)
        
        titleLabel.textColor = textColor.nsColor
    }
    
    private func constrainTitleLabel()
    {
        titleLabel.constrain(toTheLeftOf: layoutGuideRight)
        titleLabel.left >> layoutGuideLeft.right.at(relativeTitleInset)
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
    
    private var isUntitled = true
    private static let untitled = "Untitled"
    
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
        colorView.constrainToParentButBottom()
        colorView.constrain(to: layoutGuideLeft.height.at(0.25))
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
        titleContainer.constrain(to: allButTop)
        titleContainer.constrain(to: layoutGuideLeft.top)
    }
    
    private lazy var titleContainer = addForAutoLayout(LayerBackedView())
    
    // MARK: - Layout Guides
    
    private func updateLayoutConstants()
    {
        let size = layouGuideSize
        
        layoutGuideSizeConstraints.forEach { $0.constant = size }
    }
    
    private func constrainLayoutGuides()
    {
        let size = layouGuideSize
        
        layoutGuideSizeConstraints = layoutGuideLeft.constrain(to: size)
        layoutGuideLeft >> left
        layoutGuideLeft.constrain(to: bottom)
        
        layoutGuideRight.constrain(to: layoutGuideLeft.height)
        layoutGuideRight.constrain(to: layoutGuideLeft.width.at(relativeTitleInset))
        layoutGuideRight.constrain(to: bottom)
        layoutGuideRight >> right
    }
    
    private let relativeTitleInset = Float.relativeTextInset.cgFloat
    
    private var layouGuideSize: CGFloat
    {
        ItemView.heightWithSingleLine
    }
    
    private var layoutGuideSizeConstraints = [NSLayoutConstraint]()
    
    private lazy var layoutGuideLeft = addLayoutGuide()
    private lazy var layoutGuideRight = addLayoutGuide()
    
    // MARK: - List
    
    private weak var list: List?
    
    // MARK: - Observer
    
    let receiver = Receiver()
}
