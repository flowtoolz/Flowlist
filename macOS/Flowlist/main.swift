//
//  AppDelegate.swift
//  TodayList
//
//  Created by Sebastian on 12/06/17.
//  Copyright © 2017 Flowtoolz. All rights reserved.
//

import Cocoa
import Flowtoolz

class AppDelegate: NSObject, NSApplicationDelegate
{
    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        store.load()
        
        setupWindow()
        
        setupMenuOptions()
    }
    
    func applicationWillTerminate(_ notification: Notification)
    {
        store.save()
    }
    
    // MARK: - Menu
    
    func setupMenuOptions()
    {
        let quitOption = NSMenuItem(title: "Quit",
                                    action: #selector(quit),
                                    keyEquivalent: "")
        
        NSApp.mainMenu = NSMenu(title: "Menu")
        
        //quitOption.menu = NSApp.mainMenu
        
        NSApp.mainMenu?.addItem(quitOption)
    }
    
    // MARK: - Window
    
    private func setupWindow()
    {
        window.contentViewController = MainVC()
        window.styleMask = NSWindowStyleMask([.resizable, .titled, .miniaturizable, .closable, .unifiedTitleAndToolbar])
        
        let frame = NSScreen.main()?.frame ?? CGRect(x: 0, y: 0, width: 1280, height: 960)
        
        window.setFrame(CGRect(x: frame.size.width / 5,
                               y: frame.size.height / 5,
                               width: frame.size.width * 0.6,
                               height: frame.size.height * 0.6),
                        display: true)
        
        window.isReleasedWhenClosed = false
        window.title = "Flowlist"
        
        //window.toolbar = toolbar
        showWindow()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(windowWillClose),
                                               name: NSNotification.Name.NSWindowWillClose,
                                               object: nil)
    }
    
//    private lazy var toolbar: NSToolbar =
//    {
//        let bar = NSToolbar(identifier: "ToolbarIdentifier")
//        
//        bar.sizeMode = .small
//        
//        return bar
//    }()
    
    func toggleWindow()
    {
        if window.isVisible
        {
            hideWindow()
        }
        else
        {
            showWindow()
        }
    }
    
    func showWindow()
    {
        window.makeKeyAndOrderFront(self)
        
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func hideWindow()
    {
        window.orderOut(self)
    }
    
    func windowWillClose()
    {
        quit()
    }
    
    let window = NSWindow()
    
    func quit()
    {
        NSApp.terminate(nil)
    }
}

autoreleasepool
{
    let app = NSApplication.shared()
    let appDelegate = AppDelegate()
    
    app.delegate = appDelegate
    app.run()
}
