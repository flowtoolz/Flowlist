//
//  TaskVC.swift
//  TodayList
//
//  Created by Sebastian Fichtner on 08.05.15.
//  Copyright (c) 2015 Flowtoolz. All rights reserved.
//

import Foundation

class TL_TaskVC: UIViewController, UITextFieldDelegate
{
    var task : TL_Task?
    var goBackButton : UIButton = UIButton()
    var titleField : UITextField = UITextField()
    var datePicker : UIDatePicker = UIDatePicker()
    
    // MARK: view delegate
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // back button
        
//        goBackButton.backgroundColor = UIColor.whiteColor()
        goBackButton.setImage(UIImage(named: "BackArrow"), forState: .Normal)
        goBackButton.addTarget(self, action:"goBackButtonTapped",
            forControlEvents: .TouchUpInside)
        
        // title
        
        titleField.placeholder = "Task Title"
        titleField.text = task?.title
        titleField.textAlignment = NSTextAlignment.Center
        titleField.delegate = self
        titleField.layer.cornerRadius = 44.0
        titleField.font = TL_Design.font()
        
        // date picker
        
        datePicker.datePickerMode = UIDatePickerMode.Date
        datePicker.addTarget(self, action: "dateWasEdited:", forControlEvents: UIControlEvents.ValueChanged)
        
        if let d = task?.date // date is optional
        {
            datePicker.date = d
        }
        else
        {
            datePicker.date = NSDate()
        }
        
        // view
        
        view.addSubview(goBackButton)
        view.addSubview(datePicker)
        view.addSubview(titleField)
        view.backgroundColor = UIColorFromRGB(0xddffbb)
        view.setNeedsUpdateConstraints()
    }
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
    
        if titleField.text == ""
        {
            titleField.becomeFirstResponder()
        }
    }
    
    // MARK: input & interaction
    
    func goBackButtonTapped()
    {
        FT_CoreDataStack.sharedInstance.saveContext()
        
        self.presentingViewController?.dismissViewControllerAnimated(true,
            completion: nil)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        
        task?.title = titleField.text
        
        return true
    }
    
    func dateWasEdited(datePicker: UIDatePicker)
    {
        task?.date = datePicker.date
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
        
        titleField.autoSetDimension(ALDimension.Height, toSize: 88.0)
        titleField.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero,
            excludingEdge:ALEdge.Bottom)
        
        datePicker.autoPinEdgeToSuperviewEdge(ALEdge.Left)
        datePicker.autoPinEdgeToSuperviewEdge(ALEdge.Right)
        datePicker.autoPinEdge(ALEdge.Top, toEdge: ALEdge.Bottom, ofView: titleField)

        goBackButton.autoSetDimension(ALDimension.Height, toSize: 88.0)
        goBackButton.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero,
            excludingEdge:ALEdge.Top)
        
        didSetupConstraints = true
        
        super.updateViewConstraints()
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask
    {
        return UIInterfaceOrientationMask.All
    }
}