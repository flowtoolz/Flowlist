//
//  TaskStorePersister.swift
//  TodayList
//
//  Created by Sebastian on 14/06/17.
//  Copyright © 2017 Flowtoolz. All rights reserved.
//

import Foundation
import Flowtoolz

extension TaskStore
{
    func save()
    {
        var archive = [TaskArchive]()
        
        for task in tasks
        {
            archive.append(TaskArchive(with: task))
        }
        
        NSKeyedArchiver.archiveRootObject(archive, toFile: TaskStore.filePath)
    }
    
    func load()
    {
        guard let archive = NSKeyedUnarchiver.unarchiveObject(withFile: TaskStore.filePath) as? [TaskArchive]
        else
        {
            return
        }
        
        tasks.removeAll()
        
        for archiveTask in archive
        {
            tasks.append(archiveTask.task)
        }
    }
    
    private static let filePath = Bundle.main.bundlePath + "/UserData.plist"
}


