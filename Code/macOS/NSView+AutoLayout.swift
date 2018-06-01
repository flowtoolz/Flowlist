import AppKit.NSView

extension NSView
{
    func addForAutoLayout<ViewType>(_ view: ViewType) -> ViewType
        where ViewType: NSView
    {
        view.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(view)
        
        return view
    }
}
