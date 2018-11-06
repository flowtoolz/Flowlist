protocol ItemFile: AnyObject
{
    func loadItem() -> Item?
    func save(_ item: Item)
}
