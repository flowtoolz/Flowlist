//
//  ProofOfConcept.swift
//  Programmatic Mac App POC
//
//  Created by Sebastian on 17.11.19.
//  Copyright © 2019 Flowtoolz. All rights reserved.
//

import AppKit

// MARK: - App Specific Content

class MyView: View {
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        layer?.backgroundColor = .black
        
        let subview = View()
        subview.layer?.backgroundColor = .white
       
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

// MARK: - App Agnostic Types

class AppController: NSObject, NSApplicationDelegate {
    
    init(_ content: NSViewController) {
        window = NSWindow(contentViewController: content)
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        window.makeKeyAndOrderFront(nil)
    }

    private let window: NSWindow
}

class View: NSView {
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

class ViewController<ContentView: NSView>: NSViewController {

    override func loadView() { view = contentView }
    
    private let contentView = ContentView(frame: .init(origin: .zero, size: initialSize))
    
    static var initialSize: CGSize {
        .init(width: NSScreen.size.width * 0.8, height: NSScreen.size.height * 0.8)
    }
}

extension NSScreen {
    
    static var size: CGSize {
        main?.frame.size ?? CGSize(width: 1920, height: 1080)
    }
}

