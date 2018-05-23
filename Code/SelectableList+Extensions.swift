extension SelectableList
{
    func debug()
    {
        print("════════════════════════════════════════════════\n\n" + description + "\n")
    }
    
    var description: String
    {
        var desc = title.latestUpdate + ":"
        
        for i in 0 ..< numberOfTasks
        {
            guard let task = task(at: i) else { continue }
            
            desc += "\n- \(task.title.value ?? "untitled")"
        }
        
        desc += "\n\nselection: \(selection.description)"
        
        return desc
    }
}
