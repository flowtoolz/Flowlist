import Foundation

func printProductIdentifiers()
{
    let identifiers = loadProductIdentifiers()
    
    for id in identifiers
    {
        print(id)
    }
}

func loadProductIdentifiers() -> [String]
{
    guard let fileUrl = productIdentifiersFileUrl,
        let data = try? Data(contentsOf: fileUrl)
    else
    {
        return []
    }
    
    let plist = try? PropertyListSerialization.propertyList(from: data,
                                                            options: [],
                                                            format: nil)
    
    return (plist as? [String]) ?? []
}

var productIdentifiersFileUrl: URL?
{
    return Bundle.main.url(forResource: "product_identifiers",
                           withExtension: "plist")
}
