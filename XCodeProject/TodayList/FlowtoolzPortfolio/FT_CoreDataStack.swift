//
//  FT_CoreDataStack.swift
//  Flowtoolz Portfolio
//
//  Created by Sebastian Fichtner on 09.05.15.
//  Copyright (c) 2015 Flowtoolz. All rights reserved.
//

import Foundation
import CoreData

class FT_CoreDataStack
{
    // MARK: - lazy loaded properties
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.Flowtoolz.TodayList" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] 
        }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("TodayList", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
        }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("TodayList.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch var error1 as NSError {
            error = error1
            coordinator = nil
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        } catch {
            fatalError()
        }
        
        return coordinator
        }()
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
        }()
    
    // MARK: - loading and saving
    
    func createObjectOfClass(className: String) -> NSManagedObject?
    {
        if let c = managedObjectContext
        {
            return NSEntityDescription.insertNewObjectForEntityForName(className, inManagedObjectContext: c) as? NSManagedObject
        }
        
        return nil
    }
    
    func fetchObjectsOfClass(className: String) -> [NSManagedObject]
    {
        let fetchRequest = NSFetchRequest(entityName: className)
        
        if let c = managedObjectContext, fetchResults = (try? c.executeFetchRequest(fetchRequest)) as? [NSManagedObject]
        {
            return fetchResults
        }
        else
        {
            NSLog("error fetching objects of class '%@' from core data", className)
            return []
        }
    }
    
    func fetchObjectsOfClass(className: String,
        withPredicate predicate: NSPredicate) -> [NSManagedObject]
    {
        let fetchRequest = NSFetchRequest(entityName: className)
        fetchRequest.predicate = predicate
        
        if let c = managedObjectContext, fetchResults = (try? c.executeFetchRequest(fetchRequest)) as? [NSManagedObject]
        {
            return fetchResults
        }
        else
        {
            NSLog("error fetching objects of class '%@' from core data", className)
            return []
        }
    }
    
    func saveContext()
    {
        if let moc = self.managedObjectContext
        {
            var error: NSError? = nil
            if moc.hasChanges && !moc.save()
            {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog("Unresolved error \(error), \(error!.userInfo)")
                abort()
            }
            else
            {
                NSLog("either nothing changed or data saving failed")
            }
        }
    }
    
    // MARK: - singleton access & initialization
    
    func initialize()
    {
        
    }
    
    private init()
    {
        initialize()
    }
    
    class var sharedInstance: FT_CoreDataStack
    {
        struct staticData
        {
            static var instance: FT_CoreDataStack?
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&staticData.token)
            {
                staticData.instance = FT_CoreDataStack()
        }
        
        return staticData.instance!
    }
}