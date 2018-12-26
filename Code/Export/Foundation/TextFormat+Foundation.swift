import Foundation

extension TextFormat
{
    static var preferred: TextFormat
    {
        get
        {
            guard let string = defaults.string(forKey: formatKey) else
            {
                return .plain
            }
            
            return TextFormat(rawValue: string) ?? .plain
        }
        
        set
        {
            defaults.set(newValue.rawValue, forKey: formatKey)
        }
    }
    
    private static var defaults: UserDefaults { return .standard }
    
    private static var formatKey: String
    {
        return "UserDefaultsKeyExportFormat"
    }
}
