import SwiftyToolz

extension Task
{
    var description: String { return title.value ?? "untitled" }
    
    var hash: HashValue { return SwiftyToolz.hash(self) }
    
    var isDone: Bool { return state.value == .done }
    
    var indexInSupertask: Int? { return supertask?.index(of: self) }
}
