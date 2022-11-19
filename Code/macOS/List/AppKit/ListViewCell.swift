import AppKit
import GetLaid
import SwiftObserver
import SwiftyToolz

class ListViewCell: NSCollectionViewItem, Observer
{
    // MARK: - Initialize
    
    init(listView: ListView?)
    {
        self.listView = listView
        super.init(nibName: nil, bundle: nil)
        
        observe(Color.darkMode) { [weak self] _ in self?.resetShadow() }
    }
    
    required init?(coder: NSCoder) { nil }
    
    // MARK: - Load View
    
    override func loadView()
    {
        view = NSView()
        listView.forSome { view.addForAutoLayout($0) >> view }
        resetShadow()
    }
    
    private weak var listView: ListView?
    
    // MARK: - Shadow
    
    private func resetShadow()
    {
        let isDark = Color.isInDarkMode
        let opacity: Double = isDark ? 0.28 : 0.2
        let color = Color.gray(brightness: 0.5)
        let offset = CGSize(width: isDark ? -1 : 1, height: -1)
        
        let shadow = NSShadow()
        shadow.shadowColor = NSColor(color.with(alpha: opacity))
        shadow.shadowBlurRadius = 0
        shadow.shadowOffset = offset
        view.shadow = shadow
        
        view.layer?.shadowColor = NSColor(color).cgColor
        view.layer?.shadowOffset = offset
        view.layer?.shadowOpacity = Float(opacity)
        view.layer?.shadowRadius = 0
    }
    
    // MARK: - Observer
    
    let receiver = Receiver()
}
