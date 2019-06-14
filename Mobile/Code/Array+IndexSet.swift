import Foundation

extension Array {
    mutating func move(from offsets: IndexSet, to destination: Index) {
        let removedElements = remove(from: offsets)
        let validDestination = Swift.min(destination, count)
        insert(contentsOf: removedElements, at: validDestination)
    }
    
    @discardableResult
    mutating func remove(from offsets: IndexSet) -> [Element] {
        offsets.reversed()
            .compactMap { isValid(index: $0) ? remove(at: $0) : nil }
            .reversed()
    }
}
