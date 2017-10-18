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
        // if the user moves
        let newLocation = locations.last
        
        // check location is working
        //print("current user location \(newLocation)")
        
        if self.tasks.count == 0 {
            self.initUserAuth()
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
                    self.addCurrentUserLocationToFirebase()
                    
                }
                
            }
            else {
                //Update Location
                lastUpdatedTime = NSDate() as Date
                self.UpdateUserLocationServer()
                self.addCurrentUserLocationToFirebase()
            }
        
        
        // get the difference between time created and current time
       
        /*
        // check if he/she has a task that is currently active
        if self.tasks.count > 0 && self.currentUserTaskSaved == true {
            let currentUserTask = self.tasks[0]
            
            if currentUserTask?.completed == false {
                
                
                // if they have a task active, check the distance to the task
                let distanceToOwnTask = newLocation?.distance(from: CLLocation(latitude: currentUserTask!.latitude, longitude: currentUserTask!.longitude))
                
                // if the location is greater than queryDistance(200 m)
                if distanceToOwnTask! >  self.queryDistance {
                    self.currentUserTaskSaved = false
                    userMovedAway()
                    // then notify user that their task is has deleted
                  //  self.createLocalNotification(title: "You’re out of range so the quest ended :(", body: "Post again if you still need help.")

                    // delete the task
                    //self.deleteAndResetCurrentUserTask()

                    // remove own annotation from mapview
                   // self.removeCurrentUserTaskAnnotation()

                    // invalidate the timer for expiration
                    if self.expirationTimer != nil {
                        self.expirationTimer?.invalidate()
                        self.expirationTimer = nil
                    }
                }
            }
        }
 */
    }
    
    //Geo Facing for 200 meters
    func setUpGeofenceForTask(_ lat:CLLocationDegrees, _ long:CLLocationDegrees) {
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
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        userMovedAway()
        self.locationManager.stopMonitoring(for: region)
        
        }
    
    func calculateDistance(_ lat:CLLocationDegrees, _ long:CLLocationDegrees) -> Double {
        return (locationManager.location?.distance(from: CLLocation(latitude: lat, longitude: long)))!
    }
    
    func userMovedAway()  {
        var currentUserTask = self.tasks[0] as! Task
        if currentUserTask.taskDescription != "" {
            currentUserTask.completed = true;
            currentUserTask.completeType = Constants.STATUS_FOR_MOVING_OUT
            self.createLocalNotification(title: "You’re out of range so the quest ended :(", body: "Post again if you still need help.")
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
            
            //Show Alert For Location permission Denied
//            let alertView = SCLAlertView()
//            alertView.addButton("Settings") {
//                UIApplication.shared.open(URL(string:UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
//            }
//
//            alertView.showTitle(
//                "Mayo", // Title of view
//                subTitle: "Unable to get location, Please check settings.", // String of view
//                duration: 0.0, // Duration to show before closing automatically, default: 0.0
//                completeText: "Cancel", // Optional button value, default: ""
//                style: .error, // Styles - see below.
//                colorStyle: 0x508FBC,
//                colorTextButton: 0xFFFFFF
//            )
            manager.stopMonitoringSignificantLocationChanges()
            return
        }
        // Notify the user of any errors.
        
    }


}
