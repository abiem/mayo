//
//  CustomUserMapAnnotation.swift
//  Mayo-ios-client
//
//  Created by abiem  on 4/18/17.
//  Copyright © 2017 abiem. All rights reserved.
//

import UIKit
import MapKit

class CustomUserMapAnnotation: MKPointAnnotation {
    var userId: String?
    var lastUpdatedTime:Date?
    
    init(userId: String, date:Date ) {
        self.userId = userId
        self.lastUpdatedTime = date
    }
}
