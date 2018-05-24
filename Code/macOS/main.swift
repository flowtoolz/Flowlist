import AppKit

autoreleasepool
{
    let app = NSApplication.shared
    let appDelegate = AppController()
    
    app.delegate = appDelegate
    app.run()
}
