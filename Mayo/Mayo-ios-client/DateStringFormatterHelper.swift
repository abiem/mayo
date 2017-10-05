//
//  DateStringFormatterHelper.swift
//  Mayo-ios-client
//
//  Created by abiem  on 4/8/17.
//  Copyright © 2017 abiem. All rights reserved.
//
import UIKit

class DateStringFormatterHelper: NSObject {
    
    var dateformatter: DateFormatter
    
    override init() {
        dateformatter = DateFormatter()
        dateformatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        dateformatter.timeZone = NSTimeZone(name: "UTC") as TimeZone!
    }
    
    func convertStringToDate(datestring: String) -> Date{
        return dateformatter.date(from: datestring)!
    }
    
    func convertDateToString(date: Date) -> String{
        return dateformatter.string(from: date)
    }

}


