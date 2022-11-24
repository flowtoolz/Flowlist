import AppKit
import SwiftUIToolz

class GroupIcon: Icon
{
    func set(lightMode: Bool)
    {
        image = GroupIcon.iconImage(light: lightMode)
    }
    
    private static func iconImage(light: Bool) -> NSImage
    {
        light ? imageWhite : imageBlack
    }
    
    private static let imageBlack = #imageLiteral(resourceName: "container_indicator_pdf")
    private static let imageWhite = #imageLiteral(resourceName: "container_indicator_white")
}
