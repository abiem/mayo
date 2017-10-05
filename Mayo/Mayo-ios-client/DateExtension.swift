//
//  DateExtension.swift
//  Mayo-ios-client
//
//  Created by abiem  on 5/11/17.
//  Copyright © 2017 abiem. All rights reserved.
//

import UIKit

extension Date {
    
    /// Returns the amount of seconds from another date
    func seconds(from date: Date) -> Int {
        return Calendar.current.dateComponents([.second], from: date, to: self).second ?? 0
    }
    
    
}
