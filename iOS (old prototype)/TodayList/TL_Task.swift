//
//  TD_Task.swift
//  TodayList
//
//  Created by Sebastian Fichtner on 08.05.15.
//  Copyright (c) 2015 Flowtoolz. All rights reserved.
//

import Foundation
import CoreData

class TL_Task: NSManagedObject
{
    @NSManaged var title: String
    @NSManaged var date: NSDate
}
