import SwiftyToolz

extension Tree where Data == ItemData
{
    func debug()
    {
        print("════════════════════════════════════════════════\n\n" + description() + "\n")
    }
    
    func description(_ prefix: String = "", _ isLast: Bool = true) -> String
    {
        let bullet = isLast ? "└╴" : "├╴"
        var desc = "\(prefix)\(bullet)" + (data?.title.value ?? "untitled")
        
        for i in 0 ..< count
        {
            guard let subitem = self[i] else { continue }
            
            let isLastSubtask = i == count - 1
            let subitemPrefix = prefix + (isLast ? " " : "│") + " "

            desc += "\n\(subitem.description(subitemPrefix, isLastSubtask))"
        }
        
        return desc
    }
}
