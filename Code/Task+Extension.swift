import SwiftyToolz

extension Task
{
    var hash: HashValue { return SwiftyToolz.hash(self) }
    
    var isDone: Bool { return state.value == .done }
    
    var indexInSupertask: Int? { return supertask?.index(of: self) }
}
