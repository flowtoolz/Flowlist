//
//  main.swift
//  Programmatic Mac App POC
//
//  Created by Sebastian on 17.11.19.
//  Copyright © 2019 Flowtoolz. All rights reserved.
//

import AppKit

let appController = AppController(MyRootView())
NSApplication.shared.delegate = appController
NSApplication.shared.run()
