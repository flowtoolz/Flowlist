import Foundation

var productIdentifiersFileUrl: URL?
{
    return Bundle.main.url(forResource: "product_identifiers",
                           withExtension: "plist")
}
