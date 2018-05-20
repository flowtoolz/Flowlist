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
        
        for i in 0 ..< numberOfSubtasks
        {
            guard let subtask = subtask(at: i) else { continue }
            
            let isLastSubtask = i == numberOfSubtasks - 1
            let subtaskPrefix = prefix + (isLast ? " " : "│") + "  "

            desc += "\n\(subtask.description(subtaskPrefix, isLastSubtask))"
        }
        
        return desc
    }
    
    var hash: HashValue { return SwiftyToolz.hash(self) }
    
    var isDone: Bool { return state.value == .done }
    
    var indexInSupertask: Int? { return supertask?.index(of: self) }
}
