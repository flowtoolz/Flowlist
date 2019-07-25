import SwiftObserver
import SwiftyToolz

extension Color
{
    // MARK: - Color Tags
    
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
                return Color.white.with(alpha: done ? 0.5 : 1)
            }
            else
            {
                return Color.white.with(alpha: done ? grayedOutAlphaDark : 1)
            }
        }
        else
        {
            if selected
            {
                let color: Color = focused ? .white : .black
                
                return color.with(alpha: done ? 0.5 : 1)
            }
            else
            {
                return Color.black.with(alpha: done ? grayedOutAlphaLight : 1)
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
    
    static func iconAlpha(isInProgress inProgress: Bool,
                          isDone done: Bool,
                          isSelected selected: Bool) -> Float
    {
        if selected
        {
            return done ? 0.5 : 1.0
        }
        else if inProgress
        {
            return 1
        }
        else
        {
            return isInDarkMode ? grayedOutAlphaDark : grayedOutAlphaLight
        }
    }
    
    private static let grayedOutAlphaLight: Float = 0.22
    private static let grayedOutAlphaDark: Float = 0.2
    
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
    
    static var progressBarSeparator: Color
    {
        if isInDarkMode { return .black }
        
        return .gray(brightness: 0.8)
    }
    
    static var progressBar: Color
    {
        return itemBackground(isDone: false,
                              isSelected: true,
                              isTagged: false,
                              isFocusedList: true)
    }
    
    static var progressBackground: Color
    {
        return .listBackground
    }
    
    static var purchasePanelBackground: Color
    {
        return itemBackground(isDone: false,
                              isSelected: false,
                              isTagged: false,
                              isFocusedList: true)
    }
    
    // MARK: - Browser Backgrounds
    
    static var listBackground: Color
    {
        return .itemBackground(isDone: false,
                               isSelected: false,
                               isTagged: false,
                               isFocusedList: false)
    }
    
    static func itemBackground(isDone done: Bool,
                               isSelected selected: Bool,
                               isTagged tagged: Bool,
                               isFocusedList: Bool) -> Color
    {
        guard selected else
        {
            return .gray(brightness: isInDarkMode ? 0.09 : 1)
        }
        
        let brightness: Float = isInDarkMode ? (isFocusedList ? 0.333 : 0.16) : isFocusedList ? 0.5 : 0.83
        
        return Color.gray(brightness: brightness)
    }
    
    static var windowBackground: Color
    {
        return isInDarkMode ? .black : .gray(brightness: 0.91)
    }
    
    // MARK: - Basics
    
    static var isInDarkMode: Bool
    {
        get { return darkMode.latestMessage }
        set { darkModeVar <- newValue }
    }
}

let darkMode = darkModeVar.new()

fileprivate let darkModeVar = Var(false)
