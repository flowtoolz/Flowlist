import Foundation

extension Task
{
    convenience init()
    {
        self.init(with: UUID().uuidString)
    }
}
