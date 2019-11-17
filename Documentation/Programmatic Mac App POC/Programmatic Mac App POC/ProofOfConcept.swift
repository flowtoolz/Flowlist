//
//  ProofOfConcept.swift
//  Programmatic Mac App POC
//
//  Created by Sebastian on 17.11.19.
//  Copyright © 2019 Flowtoolz. All rights reserved.
//

import AppKit

// MARK: - App Specific

class MyRootView: NSView {
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        let subview = NSView()
        subview.wantsLayer = true
        subview.layer?.backgroundColor = .white
       
        subview.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subview)
        subview.heightAnchor.constraint(equalTo: heightAnchor,
                                        multiplier: 0.5).isActive = true
        subview.widthAnchor.constraint(equalTo: widthAnchor,
                                       multiplier: 0.5).isActive = true
        subview.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        subview.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
    
    required init?(coder: NSCoder) { super.init(coder: coder) }
}

// MARK: - App Agnostic

class AppController: NSObject, NSApplicationDelegate {
    
    init(_ root: NSView) {
        window = Window()
        window.contentView = root
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        window.makeKeyAndOrderFront(nil)
    }

    private let window: NSWindow
}

class Window: NSWindow {
    
    init() {
        let screenSize = NSScreen.main?.frame.size ?? CGSize(width: 1920, height: 1080)
        let contentRect = CGRect(x: screenSize.width * 0.1,
                                 y: screenSize.height * 0.1,
                                 width: screenSize.width * 0.8,
                                 height: screenSize.height * 0.8)
        super.init(contentRect: contentRect,
                   styleMask: [.closable, .titled, .miniaturizable, .resizable],
                   backing: .buffered,
                   defer: false)
        titlebarAppearsTransparent = true
    }
}
