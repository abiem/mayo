//
//  LocationManagerExtension.swift
//  Mayo-ios-client
//
//  Created by abiem  on 5/25/17.
//  Copyright © 2017 abiem. All rights reserved.
//

import UIKit
import CoreLocation
import SCLAlertView

extension MainViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // if the user moves 10 m
        self.addCurrentUserLocationToFirebase()
        
        if self.tasks.count == 0 && checkFakeTakViewed() == true {
            if (self.userLatitude != nil && self.userLongitude != nil) {
                // TODO fix
                let timeStamp = Int(NSDate.timeIntervalSinceReferenceDate*1000)
                tasks.append(
                    Task(userId: currentUserId!, taskDescription: "", latitude: self.userLatitude!, longitude: self.userLongitude!, completed: true, timeCreated: Date(), timeUpdated: Date(), taskID: "\(timeStamp)")
                )
                carouselView.reloadData()
            }
        }
        
            // get current time
            let currentTime = Date()
            if (self.lastUpdatedTime != nil) {
                let timeDifference = currentTime.seconds(from: self.lastUpdatedTime!)
                print("time difference for task: \(timeDifference)")
                
                // if time difference is greater than 10 mins (600 seconds)
                // return and don't add this task to tasks
                if timeDifference > self.LOCATION_UPDATE_IN_SECOND {
                    //Update Location
                    lastUpdatedTime = NSDate() as Date
                    self.UpdateUserLocationServer()
                }
                
            }
            else {
                //Update Location
                lastUpdatedTime = NSDate() as Date
                self.UpdateUserLocationServer()
                
            }

    }
    
    //Geo Facing for 200 meters
    func setUpGeofenceForTask(_ lat:CLLocationDegrees, _ long:CLLocationDegrees) {
        if locationManager.location?.coordinate.latitude == nil && locationManager.location?.coordinate.longitude == nil {
            return
        }
        if calculateDistance(lat, long) > 200 {
            userMovedAway()
        }
        else {
            let geofenceRegionCenter = CLLocationCoordinate2DMake(lat, long);
            let geofenceRegion = CLCircularRegion(center: geofenceRegionCenter, radius: 200, identifier: "taskDistanceExpired");
            geofenceRegion.notifyOnExit = true;
            self.locationManager.startMonitoring(for: geofenceRegion)
        }
        
    }
    // user move away task area
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        userMovedAway()
        self.locationManager.stopMonitoring(for: region)
        
        }
    
    func calculateDistance(_ lat:CLLocationDegrees, _ long:CLLocationDegrees) -> Double {
        return (locationManager.location?.distance(from: CLLocation(latitude: lat, longitude: long)))!
    }
    
    func userMovedAway()  {
        let currentUserTask = self.tasks[0]!
        if currentUserTask.taskDescription != "" {
            currentUserTask.completed = true;
            currentUserTask.completeType = Constants.STATUS_FOR_MOVING_OUT
            self.createLocalNotification(title: "You’re out of range so the quest ended :(", body: "Post again if you still need help." , time: Int(0.5))
            self.removeTaskAfterComplete(currentUserTask)
            if self.expirationTimer != nil {
                self.expirationTimer?.invalidate()
                self.expirationTimer = nil
            }
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let error = error as? CLError, error.code == .denied {
            // Location updates are not authorized.
            locationManager.stopUpdatingLocation()
            
            //Show Alert For Location permission Denied
            showLocationAlert()
           
            manager.stopMonitoringSignificantLocationChanges()
            return
        }
        // Notify the user of any errors.
        
    }
    
    func showLocationAlert() {
        let appearance = SCLAlertView.SCLAppearance(
            showCloseButton: false
        )
        let alertView = SCLAlertView(appearance: appearance)
        alertView.addButton("Settings") {
            UIApplication.shared.open(URL(string:UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
        }
        
        alertView.showTitle(
            "Mayo", // Title of view
            subTitle: "Unable to get location, Please check settings.", // String of view
            duration: 0.0, // Duration to show before closing automatically, default: 0.0
            completeText: "", // Optional button value, default: ""
            style: .error, // Styles - see below.
            colorStyle: 0x508FBC,
            colorTextButton: 0xFFFFFF
        )
    }


}
