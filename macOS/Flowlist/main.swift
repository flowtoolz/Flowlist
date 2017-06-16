//
//  AppDelegate.swift
//  TodayList
//
//  Created by Sebastian on 12/06/17.
//  Copyright © 2017 Flowtoolz. All rights reserved.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate
{
    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        taskStore.load()
        
        setupWindow()
    }
    
    func applicationWillTerminate(_ notification: Notification)
    {
        taskStore.save()
    }
    
    // MARK: - Window
    
    private func setupWindow()
    {
        window.contentViewController = MainVC()
        window.styleMask = NSWindowStyleMask([.resizable, .titled, .miniaturizable, .closable, .unifiedTitleAndToolbar])
        window.setFrame(CGRect(x: 400, y: 350, width: 800, height: 400),
                        display: true)
        window.isReleasedWhenClosed = false
        window.title = "Flowlist"
        window.toolbar = toolbar
        window.makeKeyAndOrderFront(self)
    }
    
    private lazy var toolbar: NSToolbar =
    {
        let bar = NSToolbar(identifier: "ToolbarIdentifier")
        
        bar.sizeMode = .small
        
        return bar
    }()
    
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
    
    let window = NSWindow()
    
    private func quit()
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
