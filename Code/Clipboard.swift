class Clipboard<Object: Copyable>
{
    func storeCopies(of objects: [Object])
    {
        storedObjects = objects.map { $0.copy }
    }
    
    var copiesOfStoredObjects: [Object]
    {
        return storedObjects.map { $0.copy }
    }
    
    private var storedObjects = [Object]()
}
