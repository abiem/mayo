//
//  CustomFocusCurrentUserTaskAnnotation.swift
//  Mayo-ios-client
//
//  Created by abiem  on 5/21/17.
//  Copyright © 2017 abiem. All rights reserved.
//

import UIKit
import MapKit

class CustomFocusCurrentUserTaskAnnotation: MKPointAnnotation {
    var currentCarouselIndex: Int?
    
    init(currentCarouselIndex: Int ) {
        self.currentCarouselIndex = currentCarouselIndex
    }
}
