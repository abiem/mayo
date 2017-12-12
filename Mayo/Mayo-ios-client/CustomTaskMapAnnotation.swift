//
//  CustomTaskMapAnnotation.swift
//  Mayo-ios-client
//
//  Created by abiem  on 4/21/17.
//  Copyright © 2017 abiem. All rights reserved.
//

import UIKit
import MapKit
import Cluster

class CustomTaskMapAnnotation: Annotation {
    var currentCarouselIndex: Int?
    var taskUserId: String?
    
    init(currentCarouselIndex: Int,taskUserId: String) {
        self.currentCarouselIndex = currentCarouselIndex
        self.taskUserId = taskUserId
    }
}
