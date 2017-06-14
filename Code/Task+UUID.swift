//
//  Task+UUID.swift
//  TodayList
//
//  Created by Sebastian on 14/06/17.
//  Copyright © 2017 Flowtoolz. All rights reserved.
//

import Foundation

extension Task
{
    convenience init()
    {
        self.init(with: UUID().uuidString)
    }
}
