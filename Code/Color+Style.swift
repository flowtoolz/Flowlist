import SwiftObserver
import SwiftyToolz

extension Color
{
    // MARK: - Color Tags
    
    static let colorOverlayAlpha: Float = 0.3
    static let tagBorderAlpha: Float = 0.5
    
    static let tags: [Color] =
    [
        Color(253, 74, 75),
        Color(253, 154, 57),
        Color(254, 207, 60),
        Color(95, 197, 64),
        Color(63, 169, 242),
        Color(197, 112, 219)
    ]
    
    // MARK: - Item Text
    
    static func itemText(isDone done: Bool,
                         isSelected selected: Bool,
                         isEditing editing: Bool = false) -> Color
    {
        if editing { return .text }
        
        if isInDarkMode
        {
            if selected
            {
                return Color.black.with(alpha: done ? 0.6 : 1)
            }
            else
            {
                return Color.white.with(alpha: done ? 0.5 : 1)
            }
        }
        else
        {
            if selected
            {
                return Color.white.with(alpha: done ? 0.6 : 1)
            }
            else
            {
                return Color.black.with(alpha: done ? 0.4 : 1)
            }
        }
    }
    
    static var text: Color
    {
        return isInDarkMode ? .white : .black
    }
    
    static var textSelectedBackground: Color
    {
        return .gray(brightness: isInDarkMode ? 0.4 : 0.85)
    }
    
    static var textDiscount: Color
    {
        if isInDarkMode
        {
            return Color(1, 0.35, 0.35, 0.75)
        }
        else
        {
            return Color(0.75, 0, 0, 0.75)
        }
    }
    
    // MARK: - Item Content
    
    static let doneItemIconAlpha: Float = 0.5
    
    static func itemContentIsLight(isSelected selected: Bool) -> Bool
    {
        return isInDarkMode ? !selected : selected
    }
    
    static var editingBackground: Color
    {
        return isInDarkMode ? .black : .white
    }
    
    // MARK: - Items
    
    static func itemBorder(isDone done: Bool,
                           isSelected selected: Bool) -> Color
    {
        if isInDarkMode
        {
            return Color.white.with(alpha: selected ? 1 : done ? 0.16 : 0.1)
        }
        else
        {
            return Color.black.with(alpha: 0.15)
        }
    }
    
    static func itemBackground(isDone done: Bool,
                               isSelected selected: Bool,
                               isTagged tagged: Bool) -> Color
    {
        if isInDarkMode
        {
            if selected
            {
                return tagged && !done ? .white : .gray(brightness: 0.8)
            }
            else
            {
                return done || tagged ? .black : .gray(brightness: 0.1)
            }
        }
        else
        {
            if selected
            {
                return .gray(brightness: done || !tagged ? 0.4 : 0.3)
            }
            else
            {
                return done ? .gray(brightness: brightness2) : .white
            }
        }
    }
    
    // MARK: - General Views
    
    static var progressBar: Color
    {
        return isInDarkMode ? .gray(brightness: 0.25) : .white
    }
    
    static var progressBackground: Color
    {
        return isInDarkMode ? .clear : .gray(brightness: brightness2)
    }
    
    static var border: Color
    {
        if isInDarkMode
        {
            return Color.white.with(alpha: 0.03)
        }
        else
        {
            return Color.black.with(alpha: 0.15)
        }
    }
    
    static var windowBackground: Color
    {
        return .gray(brightness: isInDarkMode ? 0 : brightness1)
    }
    
    // MARK: - Basics
    
    static var isInDarkMode: Bool
    {
        get { return darkMode.latestUpdate }
        set { darkModeVar <- newValue }
    }
    
    private static let brightness1 = brightnessFactor
    private static let brightness2 = pow(brightnessFactor, 2)
    private static let brightnessFactor: Float = 0.91
}

let darkMode = darkModeVar.new().filter({ $0 != nil }).unwrap(false)

fileprivate let darkModeVar = Var(false)
