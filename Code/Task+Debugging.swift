import SwiftyToolz

extension Task
{
    func debug()
    {
        print("════════════════════════════════════════════════\n\n" + description() + "\n")
    }
    
    func description(_ prefix: String = "", _ isLast: Bool = true) -> String
    {
        let bullet = isLast ? "└╴" : "├╴"
        var desc = "\(prefix)\(bullet)" + (title.value ?? "untitled")
        
        for i in 0 ..< numberOfBranches
        {
            guard let subtask = self[i] else { continue }
            
            let isLastSubtask = i == numberOfBranches - 1
            let subtaskPrefix = prefix + (isLast ? " " : "│") + " "

            desc += "\n\(subtask.description(subtaskPrefix, isLastSubtask))"
        }
        
        return desc
    }
}
