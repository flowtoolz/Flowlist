//
//  FT_Helpers.swift
//  TodayList
//
//  Created by Sebastian Fichtner on 09.05.15.
//  Copyright (c) 2015 Flowtoolz. All rights reserved.
//

import Foundation

// MARK: - Helpers

func printRect(rect:CGRect)
{
    NSLog("x %.0f   y %.0f   w %.0f   h %.0f",
        rect.origin.x,
        rect.origin.y,
        rect.size.width,
        rect.size.height)
}

func UIColorFromRGB(rgbValue: UInt) -> UIColor
{
    return UIColor(
        red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
        green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
        blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
        alpha: CGFloat(1.0)
    )
}