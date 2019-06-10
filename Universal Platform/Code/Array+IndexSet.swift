import Foundation

extension Array {
    
    mutating func move(from offsets: IndexSet, to destination: Index) {
        let validDestination = Swift.min(destination, count)
        let numberOfOffsetsBeforeDestination = offsets.filter { $0 < validDestination }.count
        let destinationAfterRemovingElements = validDestination - numberOfOffsetsBeforeDestination
        insert(contentsOf: remove(from: offsets), at: destinationAfterRemovingElements)
    }
    
    @discardableResult
    mutating func remove(from offsets: IndexSet) -> [Element] {
        return offsets.reversed().compactMap {
            isValid(index: $0) ? remove(at: $0) : nil
        }
    }
}
