import SwiftObserver
import SwiftyToolz

extension Color
{
    static let tags: [Color] =
    [
        Color(253, 74, 75),
        Color(253, 154, 57),
        Color(254, 207, 60),
        Color(95, 197, 64),
        Color(63, 169, 242),
        Color(197, 112, 219)
    ]
    
    static var editingBackground: Color
    {
        return isInDarkMode ? .black : .white
    }
    
    static func itemBackground(isDone done: Bool,
                               isSelected selected: Bool) -> Color
    {
        if isInDarkMode
        {
            if selected
            {
                return .white
            }
            else
            {
                return done ? .black : .gray(brightness: 0.2)
            }
        }
        else
        {
            if selected
            {
                return .black
            }
            else
            {
                return done ? .gray(brightness: brightness2) : .white
            }
        }
    }
    
    static var itemBorder: Color
    {
        if isInDarkMode
        {
            return Color.white.with(alpha: 0.1)
        }
        else
        {
            return Color.black.with(alpha: 0.15)
        }
    }
    
    static var listBorder: Color
    {
        if isInDarkMode
        {
            return Color.white.with(alpha: 0.1)
        }
        else
        {
            return Color.black.with(alpha: 0.15)
        }
    }
    
    static var text: Color
    {
        return isInDarkMode ? .white : .black
    }
    
    static func itemText(isDone done: Bool,
                         isSelected selected: Bool) -> Color
    {
        if isInDarkMode
        {
            if selected
            {
                return Color.black.with(alpha: done ? 0.5 : 1)
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
                return Color.white.with(alpha: done ? 0.5 : 1)
            }
            else
            {
                return Color.black.with(alpha: done ? 0.5 : 1)
            }
        }
    }
    
    static func itemContentIsLight(isSelected selected: Bool) -> Bool
    {
        return isInDarkMode ? !selected : selected
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
    
    static var progressBar: Color
    {
        return isInDarkMode ? .gray(brightness: 0.25) : .white
    }
    
    static var background: Color
    {
        return .gray(brightness: isInDarkMode ? 0.1 : brightness1)
    }
    
    static var windowBackground: Color
    {
        return .gray(brightness: isInDarkMode ? 0 : brightness2)
    }
    
    static var isInDarkMode: Bool
    {
        get { return darkMode.latestUpdate }
        set { darkModeVar <- newValue }
    }
    
    private static let brightness1 = brightnessFactor
    private static let brightness2 = pow(brightnessFactor, 2)
    private static let brightnessFactor: Float = 0.92
}

let darkMode = darkModeVar.new().filter({ $0 != nil }).unwrap(false)

fileprivate let darkModeVar = Var(true)
