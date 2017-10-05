//
//  Task.swift
//  Mayo-ios-client
//
//  Created by abiem  on 4/8/17.
//  Copyright © 2017 abiem. All rights reserved.
//

import UIKit
import Firebase
import GeoFire

class Task: NSObject {
   
    
    
    var userId: String
    var latitude: CLLocationDegrees
    var longitude: CLLocationDegrees
    var taskDescription: String
    var completed: Bool
    var timeCreated: Date
    var timeUpdated: Date
    var ref: FIRDatabaseReference
    var tasksRef: FIRDatabaseReference
    var tasksLocationsRef: FIRDatabaseReference
    var geoFire: GeoFire!
    var timeCreatedString: String
    var timeUpdatedString: String
    var startColor: String?
    var endColor: String?
    var taskID: String?
    var createdby: String?
    

    
    init(userId: String , taskDescription: String, latitude: CLLocationDegrees, longitude: CLLocationDegrees, completed: Bool, timeCreated: Date = Date(), timeUpdated: Date = Date(), taskID : String ) {
        
        self.userId = userId
        self.taskDescription = taskDescription
        self.latitude = latitude
        self.longitude = longitude
        self.completed = completed
        self.timeCreated = timeCreated
        self.timeUpdated = timeUpdated
        self.taskID = taskID
        
//        self.startColor = startColor
//        self.endColor = endColor
        
        // create new task object
        // setup firebase database
        ref = FIRDatabase.database().reference()
        
        // setup users ref
        tasksRef = ref.child("tasks")
        
        // setup tasks locaiton ref
        tasksLocationsRef = ref.child("tasks_locations")
        
        // setup geofire reference
        geoFire = GeoFire(firebaseRef: tasksLocationsRef)
        
        
        
        // create new date formatter
        let dateformatter = DateStringFormatterHelper()
        
        // convert timeCreated and timeUpdated to string
        timeCreatedString = dateformatter.convertDateToString(date: self.timeCreated)
        timeUpdatedString = dateformatter.convertDateToString(date: self.timeUpdated)
        
    }
    
    func setGradientColors(startColor: String?, endColor: String?){
        self.startColor = startColor
        self.endColor = endColor
    }
    
    
    func save() {
        
        // save task to database
        // create new task with user id as identifier
        
        let taskDictionary: [String: Any] = [
            "taskDescription": self.taskDescription,
            "timeCreated": self.timeCreatedString,
            "timeUpdated": self.timeUpdatedString,
            "completed": self.completed,
            "startColor": self.startColor,
            "endColor": self.endColor,
            "createdby": userId,
            "taskID": self.taskID! ]
        tasksRef.child(self.taskID!).setValue(taskDictionary)
        
        
        // save task location to database with user id as key
        geoFire?.setLocation(CLLocation(latitude:latitude, longitude: longitude), forKey: "\(self.taskID!)") { (error) in
            if (error != nil) {
                print("An error occured: \(String(describing: error))")
            } else {
                print("Saved task location successfully!")
            }
        }

        
        
    }
    
}
