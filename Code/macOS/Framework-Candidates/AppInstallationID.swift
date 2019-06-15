let appInstallationID: String =
{
    let key = "UserDefaultsKeyAppInstallationID"
    if let storedID = Persistent.string[key] { return storedID }
    let id = String.makeUUID()
    Persistent.string[key] = id
    return id
}()
