import SwiftObserver
import SwiftyToolz

extension Task: Copyable
{
    convenience init(with original: Task)
    {
        self.init(with: original, root: nil)
    }
    
    convenience init(with original: Task, root: Task? = nil)
    {
        self.init(original.title.value,
                  state: original.state.value,
                  root: root,
                  numberOfLeafs: original.numberOfLeafs)
        
        for subtask in original.branches
        {
            let subCopy = Task(with: subtask, root: self)
            
            branches.append(subCopy)
        }
    }
}
