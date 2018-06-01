extension Copyable
{
    var copy: Self { return Self(with: self) }
}

protocol Copyable: AnyObject
{
    init(with original: Self)
}
