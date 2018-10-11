extension SelectableList
{
    func debug()
    {
        print("════════════════════════════════════════════════\n\n" + description + "\n")
    }
    
    var description: String
    {
        var desc = (title.latestUpdate ?? "untitled") + ":"
        
        for i in 0 ..< count
        {
            guard let task = self[i] else { continue }
            
            desc += "\n- \(task.data?.title.value ?? "untitled")"
        }
        
        desc += "\n\nselection: \(selection.description)"
        
        return desc
    }
}
