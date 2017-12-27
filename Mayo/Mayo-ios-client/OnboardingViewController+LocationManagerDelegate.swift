//
//  OnboardingViewController+LocationManagerDelegate.swift
//  Mayo-ios-client
//
//  Created by Lakshmi Kodali on 27/12/17.
//  Copyright © 2017 Weijie. All rights reserved.
//

import Foundation
import CoreLocation

extension OnboardingViewController: CLLocationManagerDelegate {
  
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    var shouldIAllow = false
    var locationStatus = ""
    
    switch status {
      
    case CLAuthorizationStatus.restricted:
      locationStatus = "Restricted Access to location"
    case CLAuthorizationStatus.denied:
      locationStatus = "User denied access to location"
    case CLAuthorizationStatus.notDetermined:
      locationStatus = "Status not determined"
      return
    default:
      locationStatus = "Allowed to location Access"
      shouldIAllow = true
    }
    
    if (shouldIAllow == true) {
      NSLog("Location to Allowed")
      
      // Start location services
      locationManager.startUpdatingLocation()
      gotoMainViewController()
      
    } else {
      NSLog("Denied access: \(locationStatus)")
      gotoMainViewController()
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    print("didFailWithError")
    gotoMainViewController()
  }
}
