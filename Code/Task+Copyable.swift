import SwiftObserver

extension Task: Copyable
{
    convenience init(with original: Task)
    {
        self.init()
        
        title <- original.title.value
        state <- original.state.value
        root = original.root
        
        for subtask in original.branches
        {
            branches.append(Task(with: subtask))
        }
    }
}
