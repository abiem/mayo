//
//  CustomFocusTaskMapAnnotation.swift
//  Mayo-ios-client
//
//  Created by abiem  on 4/25/17.
//  Copyright © 2017 abiem. All rights reserved.
//

import UIKit
import MapKit
import Cluster

class CustomFocusTaskMapAnnotation: Annotation {
    var currentCarouselIndex: Int?
    var taskUserId: String?
    
    init(currentCarouselIndex: Int, taskUserId: String ) {
        self.currentCarouselIndex = currentCarouselIndex
        self.taskUserId = taskUserId
    }
}
