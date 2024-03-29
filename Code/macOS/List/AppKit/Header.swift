import AppKit
import SwiftUIToolz
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
        
        topSpacer.layer?.cornerRadius = Double.listCornerRadius
        
        topSpacer.set(backgroundColor: .listBackground)
        titleContainer.set(backgroundColor: .listBackground)
        
        icon.isHidden = true
        
        observe(Color.darkMode)
        {
            [weak self] _ in
            
            self?.updateTitleColor()
            self?.icon.image = Header.iconImage
            
            let bgColor = Color.listBackground
            
            self?.topSpacer.set(backgroundColor: bgColor)
            self?.titleContainer.set(backgroundColor: bgColor)
        }
        
        observe(Font.baseSize)
        {
            [weak self] _ in
            
            self?.updateLayoutConstants()
            self?.titleLabel.font = Font.listTitle.nsFont
        }
    }
    
    required init?(coder decoder: NSCoder) { nil }
    
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
        icon >> centerX
        icon >> layoutGuideLeft.size.at(0.64)
        icon.centerY >> bottom.at(0.58)
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
        
        titleLabel.textColor = NSColor(textColor)
    }
    
    private func constrainTitleLabel()
    {
        titleLabel.right >> layoutGuideRight.left
        titleLabel.left >> layoutGuideLeft.right.at(relativeTitleInset)
        titleLabel.centerY >> titleContainer.bottom.at(0.436)
    }
    
    private lazy var titleLabel: Label =
    {
        let label = titleContainer.addForAutoLayout(Label())
        
        label.textColor = NSColor(Color.text)
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
            colorView.set(backgroundColor: Color.tags[tagValue])
            colorView.isHidden = false
        }
        else
        {
            colorView.isHidden = true
        }
    }
    
    private func constrainColorView()
    {
        colorView >> topSpacer.allButBottom
        colorView >> layoutGuideLeft.height.at(0.25)
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
        topSpacer >> self
    }
    
    private lazy var topSpacer = addForAutoLayout(LayerBackedView())
    
    // MARK: - Title Container
    
    private func constrainTitleContainer()
    {
        titleContainer >> allButTop
        titleContainer >> layoutGuideLeft.top
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
        
        layoutGuideSizeConstraints = layoutGuideLeft >> size
        layoutGuideLeft >> left
        layoutGuideLeft >> bottom
        
        layoutGuideRight >> layoutGuideLeft.height
        layoutGuideRight >> layoutGuideLeft.width.at(relativeTitleInset)
        layoutGuideRight >> bottom
        layoutGuideRight >> right
    }
    
    private let relativeTitleInset = Double.relativeTextInset
    
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
