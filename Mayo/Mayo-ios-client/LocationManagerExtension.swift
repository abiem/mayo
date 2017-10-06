//
//  LocationManagerExtension.swift
//  Mayo-ios-client
//
//  Created by abiem  on 5/25/17.
//  Copyright © 2017 abiem. All rights reserved.
//

import UIKit
import CoreLocation

extension MainViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // if the user moves
        let newLocation = locations.last
        
        // check location is working
        //print("current user location \(newLocation)")
        
      
            
            // get current time
            let currentTime = Date()
            if (self.lastUpdatedTime != nil) {
                let timeDifference = currentTime.seconds(from: self.lastUpdatedTime!)
                print("time difference for task: \(timeDifference)")
                
                // if time difference is greater than 1 hour (3600 seconds)
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
        
        
        // get the difference between time created and current time
       
        
        // check if he/she has a task that is currently active
        if self.tasks.count > 0 {
            let currentUserTask = self.tasks[0]
            
            if currentUserTask?.completed == false {
                
                
                // if they have a task active, check the distance to the task
                let distanceToOwnTask = newLocation?.distance(from: CLLocation(latitude: currentUserTask!.latitude, longitude: currentUserTask!.longitude))
                
                // if the location is greater than queryDistance(200 m)
                if distanceToOwnTask! >  self.queryDistance {
                    
                    // then notify user that their task is has deleted
                    self.createLocalNotification(title: "You’re out of range so the quest ended :(", body: "Post again if you still need help.")
                    
                    // delete the task
                    self.deleteAndResetCurrentUserTask()
                    
                    // remove own annotation from mapview
                    self.removeCurrentUserTaskAnnotation()
                    
                    // invalidate the timer for expiration
                    if self.expirationTimer != nil {
                        self.expirationTimer?.invalidate()
                        self.expirationTimer = nil
                    }
                }
            }
        }
    }
}
