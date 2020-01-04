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
    
    required init?(coder: NSCoder) { fatalError() }
    
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
        let opacity: Float = isDark ? 0.28 : 0.2
        let color = Color.gray(brightness: 0.5)
        let offset = CGSize(width: isDark ? -1 : 1, height: -1)
        
        let shadow = NSShadow()
        shadow.shadowColor = color.with(alpha: opacity).nsColor
        shadow.shadowBlurRadius = 0
        shadow.shadowOffset = offset
        view.shadow = shadow
        
        view.layer?.shadowColor = color.cgColor
        view.layer?.shadowOffset = offset
        view.layer?.shadowOpacity = opacity
        view.layer?.shadowRadius = 0
    }
    
    // MARK: - Observer
    
    let receiver = Receiver()
}
