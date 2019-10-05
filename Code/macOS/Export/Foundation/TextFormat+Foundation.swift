import Foundation

extension TextFormat
{
    static var preferred: TextFormat
    {
        get { TextFormat(rawValue: persistentTextFormat.value) ?? .plain }
        
        set { persistentTextFormat.value = newValue.rawValue }
    }
}

private var persistentTextFormat = PersistentString("UserDefaultsKeyExportFormat",
                                                    default: TextFormat.plain.rawValue)
