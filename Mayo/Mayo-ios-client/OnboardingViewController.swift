//
//  OnboardingViewController.swift
//  Mayo-ios-client
//
//  Created by Lakshmi Kodali on 20/12/17.
//  Copyright © 2017 Weijie. All rights reserved.
//

import UIKit
import iCarousel

class OnboardingViewController: UIViewController {
  
  @IBOutlet weak var mCarousel: iCarousel!
  
    override func viewDidLoad() {
        super.viewDidLoad()
      mCarousel.type = iCarouselType.linear
      mCarousel.isPagingEnabled = true
      mCarousel.bounces = true
      mCarousel.bounceDistance = 0.2
      mCarousel.scrollSpeed = 1.0
      
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
      
    }
  
}
