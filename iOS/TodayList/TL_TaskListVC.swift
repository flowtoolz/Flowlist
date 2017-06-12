//
//  ViewController.swift
//  TodayList
//
//  Created by Sebastian Fichtner on 08.05.15.
//  Copyright (c) 2015 Flowtoolz. All rights reserved.
//

import UIKit

class TL_TaskListVC: UIViewController, UITableViewDataSource, UITableViewDelegate
{
    let coreDataStack = FT_CoreDataStack.sharedInstance
    
    var todayTableViewTarget = TL_TodayTableViewTarget()
    
    var todayTaskArray = [TL_Task]()
    
    var inboxTableView : UITableView = UITableView()
    var todayTableView : UITableView = UITableView()
    var addNewButton : UIButton = UIButton()
    var inboxButton : UIButton = UIButton()
    var todayButton : UIButton = UIButton()

    // MARK: view delegate
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        inboxTableView.delegate = self
        inboxTableView.dataSource = self
        inboxTableView.backgroundColor = UIColor.clearColor()
        inboxTableView.tableFooterView = UIView()
        inboxTableView.separatorStyle = UITableViewCellSeparatorStyle.None
        
        todayTableView.delegate = self
        todayTableView.dataSource = self
        todayTableView.backgroundColor = UIColor.redColor()
        todayTableView.tableFooterView = UIView()
        todayTableView.separatorStyle = UITableViewCellSeparatorStyle.None
        todayTableView.hidden = true
        
        todayTableViewTarget = TL_TodayTableViewTarget()
        todayTableViewTarget.tableView = todayTableView
        
        addNewButton.backgroundColor = UIColor.whiteColor()
        addNewButton.setImage(UIImage(named: "Plus"), forState: .Normal)
        addNewButton.addTarget(self, action:"addNewButtonTapped",
            forControlEvents: .TouchUpInside)
        
        addNewButton.layer.shadowOffset = CGSizeMake(0.0, 0.0)
        addNewButton.layer.shadowRadius = 6.0
        addNewButton.layer.shadowColor = UIColor.blackColor().CGColor
        addNewButton.layer.shadowOpacity = 0.2
        
        inboxButton.backgroundColor = UIColor.whiteColor()
        inboxButton.setImage(UIImage(named: "Inbox"), forState: .Normal)
        inboxButton.addTarget(self, action:"inboxButtonTapped",
            forControlEvents: .TouchUpInside)
        
        inboxButton.layer.shadowOffset = CGSizeMake(0.0, 9.0)
        inboxButton.layer.shadowRadius = 6.0
        inboxButton.layer.shadowColor = UIColor.blackColor().CGColor
        inboxButton.layer.shadowOpacity = 0.2

        todayButton.titleLabel?.translatesAutoresizingMaskIntoConstraints = false
        todayButton.imageView?.translatesAutoresizingMaskIntoConstraints = false
        todayButton.backgroundColor = UIColorFromRGB(0xf4f4f4)
        todayButton.setImage(UIImage(named: "Today"), forState: .Normal)
        todayButton.addTarget(self, action:"todayButtonTapped",
            forControlEvents: .TouchUpInside)
        todayButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
        todayButton.titleLabel?.textAlignment = NSTextAlignment.Center
        todayButton.imageView?.contentMode = UIViewContentMode.Center
        todayButton.titleLabel?.font = TL_Design.font()
        
        todayButton.layer.shadowOffset = CGSizeMake(0.0, 9.0)
        todayButton.layer.shadowRadius = 6.0
        todayButton.layer.shadowColor = UIColor.blackColor().CGColor
        todayButton.layer.shadowOpacity = 0.2
            
        view.backgroundColor = UIColorFromRGB(0xdddddd)
        view.addSubview(inboxTableView)
        view.addSubview(todayTableView)
        view.addSubview(todayButton)
        view.addSubview(addNewButton)
        view.addSubview(inboxButton)
        view.setNeedsUpdateConstraints()
        
        inboxTableView.registerClass(TL_TableViewCell.classForCoder(),
            forCellReuseIdentifier: cellIdentifier)
        
        todayTableView.registerClass(TL_TableViewCell.classForCoder(),
            forCellReuseIdentifier: cellIdentifier)
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        
        // update table
        
        let model = TL_Model.sharedInstance
            
        model.taskArray = coreDataStack.fetchObjectsOfClass("TL_Task") as! [TL_Task]
        
        todayTaskArray = model.getTasksOfToday()
            
        /*
        // use predicate to fetch only today's tasks
        let now = NSDate()
        
        let calendar = NSCalendar(calendarIdentifier:NSCalendarIdentifierGregorian)
        
        var components = calendar?.components(NSCalendarUnit.CalendarUnitDay | NSCalendarUnit.CalendarUnitYear | NSCalendarUnit.CalendarUnitMonth,
            fromDate: now)
    
        components?.year
        components?.month
        components?.day
        
        var predicate = NSPredicate(format: "startDate <= %@ AND endDate >= %@)",
            argumentArray: [now, now])
        
        todayTaskArray = coreDataStack.fetchObjectsOfClass("TL_Task",
            withPredicate: predicate) as! [TL_Task]
*/

        inboxTableView.reloadData()
        todayTableView.reloadData()
        
        // day number
        
        let components = NSCalendar.currentCalendar().components(
            NSCalendarUnit.Day,
            fromDate: NSDate())
        
        todayButton.setTitle(String(components.day), forState: .Normal)
    }
    
    // MARK: input & interaction
    
    func addNewButtonTapped()
    {
        if let newTask = coreDataStack.createObjectOfClass("TL_Task") as? TL_Task
        {
            newTask.title = ""
            newTask.date = NSDate()
            
            coreDataStack.saveContext()
        
            let taskVC = TL_TaskVC()
            taskVC.task = newTask

            taskVC.modalTransitionStyle = UIModalTransitionStyle.FlipHorizontal
            self.presentViewController(taskVC, animated: true, completion: nil)
        }
    }
    
    func inboxButtonTapped()
    {
        todayTableView.hidden = true
        inboxTableView.hidden = false
        inboxButton.backgroundColor = UIColor.whiteColor()
        todayButton.backgroundColor = UIColorFromRGB(0xf4f4f4)
        view.bringSubviewToFront(addNewButton)
        view.bringSubviewToFront(inboxButton)
    }
    
    func todayButtonTapped()
    {
        todayTableView.hidden = false
        inboxTableView.hidden = true
        todayButton.backgroundColor = UIColor.whiteColor()
        inboxButton.backgroundColor = UIColorFromRGB(0xf4f4f4)
        view.bringSubviewToFront(addNewButton)
        view.bringSubviewToFront(todayButton)
    }
    
    func checkBoxTapped(sender: UIButton)
    {
        NSLog("ckecked inbox")
        if let parentCell = sender.superview as? TL_TableViewCell
        {
            if let indexPath = inboxTableView.indexPathForCell(parentCell),
            context = coreDataStack.managedObjectContext
            {
                let model = TL_Model.sharedInstance
                
                let task : TL_Task = model.taskArray.removeAtIndex(indexPath.row)
               
                // remove from core date
                context.deleteObject(task)
                coreDataStack.saveContext()
                
                // remove from table view
                inboxTableView.beginUpdates()
                
                inboxTableView.deleteRowsAtIndexPaths([indexPath],
                    withRowAnimation: UITableViewRowAnimation.Right)
                
                inboxTableView.endUpdates()
            }
        }
    }
    
    func tableView(tableView: UITableView,
        didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let tvc = TL_TaskVC()
        
        if tableView == inboxTableView // TODO: rename self tableview->inboxTableView
        {
            tvc.task = TL_Model.sharedInstance.taskArray[indexPath.row]
        }
        else // today's tasks
        {
            tvc.task = todayTaskArray[indexPath.row]
        }
        
        // necessary due to apple bug: http://stackoverflow.com/questions/21075540/presentviewcontrolleranimatedyes-view-will-not-appear-until-user-taps-again
        dispatch_async(dispatch_get_main_queue())
        {
            tvc.modalTransitionStyle = UIModalTransitionStyle.FlipHorizontal
            self.presentViewController(tvc, animated: true, completion: nil)
        }
    }
    
    // MARK: autolayout
    
    var didSetupConstraints : Bool = false
    
    override func updateViewConstraints()
    {
        if (didSetupConstraints)
        {
            super.updateViewConstraints()
            return
        }
    
        let insets = UIEdgeInsetsMake(0, 0, 2 * 88.0, 0)

        inboxTableView.autoPinEdgesToSuperviewEdgesWithInsets(insets)
        todayTableView.autoPinEdgesToSuperviewEdgesWithInsets(insets)

        inboxButton.autoPinEdgeToSuperviewEdge(ALEdge.Left)
        inboxButton.autoPinEdgeToSuperviewEdge(ALEdge.Bottom)
        inboxButton.autoConstrainAttribute(ALAttribute.Width,
            toAttribute: ALAttribute.Width,
            ofView: view,
            withMultiplier: 0.5)
        inboxButton.autoSetDimension(ALDimension.Height, toSize: 88.0)

        todayButton.removeConstraints(todayButton.constraints)
        
        if let constraints = todayButton.titleLabel?.constraints
        {
            todayButton.titleLabel?.removeConstraints(constraints)
        }
        
        
        if let constraints = todayButton.imageView?.constraints
        {
            todayButton.imageView?.removeConstraints(constraints)
        }
        
        todayButton.titleLabel?.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
        todayButton.imageView?.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
        
        todayButton.autoPinEdgeToSuperviewEdge(ALEdge.Right)
        todayButton.autoPinEdgeToSuperviewEdge(ALEdge.Bottom)
        todayButton.autoPinEdge(ALEdge.Left, toEdge: ALEdge.Right, ofView: inboxButton)
        todayButton.autoSetDimension(ALDimension.Height, toSize: 88.0)

        addNewButton.autoSetDimension(ALDimension.Height, toSize: 88.0)
        addNewButton.autoPinEdgeToSuperviewEdge(ALEdge.Left)
        addNewButton.autoPinEdgeToSuperviewEdge(ALEdge.Right)
        addNewButton.autoPinEdge(ALEdge.Bottom, toEdge: ALEdge.Top, ofView: inboxButton)

        didSetupConstraints = true
        
        super.updateViewConstraints()
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask
    {
        return UIInterfaceOrientationMask.All
    }

    // MARK: data source
    
    let cellIdentifier = "CellIdentifier"
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(tableView: UITableView,
        numberOfRowsInSection section: Int) -> Int
    {
        let model = TL_Model.sharedInstance
        
        if tableView == self.inboxTableView
        {
            return model.taskArray.count
        }
        else
        {
            return todayTaskArray.count
        }
    }
    
    func tableView(tableView: UITableView,
        cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! TL_TableViewCell
        
        let model = TL_Model.sharedInstance
        
        var task : TL_Task
        
        var checkView = UIButton()
        
        if tableView == self.inboxTableView
        {
            task = model.taskArray[indexPath.row]
            
            checkView.addTarget(self, action: "checkBoxTapped:",
                forControlEvents: UIControlEvents.TouchUpInside)
        }
        else
        {
            task = todayTaskArray[indexPath.row]
            
            checkView.addTarget(self.todayTableViewTarget,
                action: "checkBoxTapped:",
                forControlEvents: UIControlEvents.TouchUpInside)
        }
        
        cell.textLabel?.text = task.title
        
        

        checkView.frame = CGRectMake(0, 0, 60, 60)
        checkView.layer.cornerRadius = 30
        /*
        checkView.layer.borderWidth = 1.0
        checkView.layer.borderColor = UIColorFromRGB(0xe7e7e7).CGColor
        */
        checkView.setImage(UIImage(named: "CheckMark"), forState: .Normal)
        checkView.imageView?.contentMode = UIViewContentMode.Center
        checkView.backgroundColor = UIColorFromRGB(0xf4f4f4)
        checkView.contentMode = UIViewContentMode.ScaleAspectFit
        
        cell.accessoryView = checkView
        cell.selectionStyle = UITableViewCellSelectionStyle.Default
        cell.selectedBackgroundView = UIView(frame: cell.bounds)
        cell.selectedBackgroundView.layer.cornerRadius = 44
        cell.selectedBackgroundView.backgroundColor = UIColorFromRGB(0xddffbb)
        cell.layer.cornerRadius = 44
        cell.layer.shadowOffset = CGSizeMake(0.0, 0.0)
        cell.layer.shadowRadius = 3.0
        cell.layer.shadowColor = UIColor.blackColor().CGColor
        cell.layer.shadowOpacity = 0.2
        cell.textLabel?.backgroundColor = UIColor.clearColor()
        cell.textLabel?.font = TL_Design.font()
        cell.separatorInset = UIEdgeInsetsMake(0, 33, 0, 0)
        cell.backgroundColor = UIColor.whiteColor()
    
        return cell
    }
    
    func tableView(tableView: UITableView,
        heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 88.0
    }
}

class TL_TableViewCell: UITableViewCell
{
    
}

class TL_TodayTableViewTarget
{
    var tableView : UITableView?
    
    func checkBoxTapped(sender: UIButton)
    {
        NSLog("checked today view")
        if let parentCell = sender.superview as? TL_TableViewCell,
            tv = tableView
        {
            if let indexPath = tv.indexPathForCell(parentCell),
                context = FT_CoreDataStack.sharedInstance.managedObjectContext
            {
                let model = TL_Model.sharedInstance
                
                let task : TL_Task = model.taskArray.removeAtIndex(indexPath.row)
                
                // remove from core date
                context.deleteObject(task)
                FT_CoreDataStack.sharedInstance.saveContext()
                
                // remove from table view
                tv.beginUpdates()
                
                tv.deleteRowsAtIndexPaths([indexPath],
                    withRowAnimation: UITableViewRowAnimation.Right)
                
                tv.endUpdates()
            }
        }
    }
}