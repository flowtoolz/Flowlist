import SwiftObserver
import SwiftyToolz

extension Color
{
    // MARK: - Color Tags
    
    static let colorOverlayAlpha: Float = 1
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
                         isFocused focused: Bool,
                         isEditing editing: Bool = false) -> Color
    {
        if editing { return .text }
        
        if isInDarkMode
        {
            if selected
            {
                return Color.white.with(alpha: done ? doneAlpha : 1)
            }
            else
            {
                return Color.white.with(alpha: done ? doneAlpha : 1)
            }
        }
        else
        {
            if selected && focused
            {
                return Color.white.with(alpha: done ? doneAlpha : 1)
            }
            else
            {
                return Color.black.with(alpha: done ? doneAlpha : 1)
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
    
    static let doneAlpha: Float = 0.25
    
    static func itemContentIsLight(isSelected selected: Bool,
                                   isFocused focused: Bool) -> Bool
    {
        return isInDarkMode ? true : selected && focused
    }
    
    static var editingBackground: Color
    {
        return isInDarkMode ? .black : .white
    }
    
    // MARK: - Purchase Panel Views
    
    static var progressBar: Color
    {
        return .gray(brightness: isInDarkMode ? 0.25 : 1)
    }
    
    static var progressBackground: Color
    {
        return isInDarkMode ? .listBackground : .gray(brightness: 0.9)
    }
    
    static var purchasePanelBackground: Color
    {
        return itemBackground(isDone: false,
                              isSelected: false,
                              isTagged: false,
                              isFocusedList: true)
    }
    
    // MARK: - Browser Backgrounds
    
    static func itemBackground(isDone done: Bool,
                               isSelected selected: Bool,
                               isTagged tagged: Bool,
                               isFocusedList: Bool) -> Color
    {
        guard selected else
        {
            return .gray(brightness: isInDarkMode ? 0.09 : 1)
        }
        
        let brightness: Float = isInDarkMode ? 1.0 / (isFocusedList ? 3 : 6) : isFocusedList ? 0.5 : 0.75
        
        return Color.gray(brightness: brightness)
    }

    static var listBackground: Color
    {
        return .clear
    }
    
    static var windowBackground: Color
    {
        return isInDarkMode ? .black : .gray(brightness: 0.91)
    }
    
    // MARK: - Basics
    
    static var isInDarkMode: Bool
    {
        get { return darkMode.latestUpdate }
        set { darkModeVar <- newValue }
    }
}

let darkMode = darkModeVar.new().filter({ $0 != nil }).unwrap(false)

fileprivate let darkModeVar = Var(false)
