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
        
        // if the user moves 20 m
        let archived = NSKeyedArchiver.archivedData(withRootObject: locations.first!)
        UserDefaults.standard.setValue(archived, forKey: Constants.LOCATION)
        self.addCurrentUserLocationToFirebase()
        if self.tasks.count == 0 && checkFakeTakViewed() == true {
            if (self.userLatitude != nil && self.userLongitude != nil) {
                // TODO fix
                let timeStamp = Int(NSDate.timeIntervalSinceReferenceDate*1000)
                tasks.append(
                    Task(userId: currentUserId!, taskDescription: "", latitude: self.userLatitude!, longitude: self.userLongitude!, completed: false, timeCreated: Date(), timeUpdated: Date(), taskID: "\(timeStamp)", recentActivity : false, userMovedOutside: false )
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
        if currentUserTask.taskDescription != "" && currentUserTask.userMovedOutside == false {
            checkTaskRecentActivity(currentUserTask , callBack: { (isActivity) in
                if isActivity {
                    currentUserTask.userMovedOutside = true
                    self.tasks[0] = currentUserTask
                    currentUserTask.updateFirebaseTask()
                } else {
                    currentUserTask.completed = true;
                    currentUserTask.completeType = Constants.STATUS_FOR_MOVING_OUT
                    self.createLocalNotification(title: "You’re out of range so the quest ended :(", body: "Post again if you still need help." , time: Int(0.5))
                    self.removeTaskAfterComplete(currentUserTask)
                    if self.expirationTimer != nil {
                        self.expirationTimer?.invalidate()
                        self.expirationTimer = nil
                    }
                }
            })
            
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let error = error as? CLError, error.code == .denied {
            // Location updates are not authorized.
            locationManager.stopUpdatingLocation()
            locationManager.stopUpdatingHeading()
            manager.stopMonitoringSignificantLocationChanges()
            //Show Alert For Location permission Denied
            self.isLocationNotAuthorised = true
            showLocationAlert()
            return
        }
        // Notify the user of any errors.
        
    }
    
    func showLocationAlert() {
        CMAlertController.sharedInstance.showAlert(nil, Constants.sLOCATION_ERROR, ["Not now", "Settings"]) { (sender) in
            if let button = sender {
                if button.tag == 1 {
                    // for Move to Settings
                    UIApplication.shared.open(URL(string:UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
                }
            }
        }

    }
    

}
