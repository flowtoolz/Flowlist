//
//  TL_Design.swift
//  TodayList
//
//  Created by Sebastian Fichtner on 10.05.15.
//  Copyright (c) 2015 Flowtoolz. All rights reserved.
//

import Foundation

class TL_Design
{
    static let fontSize : CGFloat = 20.0
    
    private static var _font : UIFont?
    
    class func font() -> UIFont
    {
        if let font = _font
        {
            return font
        }
        else if let font = UIFont(name: "Helvetica-light", size: fontSize)
        {
            _font = font
            return font
        }
        else
        {
            let font = UIFont.systemFontOfSize(fontSize, weight: 1.0)
            _font = font
            return font
        }
    }
}