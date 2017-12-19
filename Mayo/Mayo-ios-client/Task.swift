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
    var userRef: FIRDatabaseReference
    var tasksLocationsRef: FIRDatabaseReference
    var geoFire: GeoFire!
    var timeCreatedString: String
    var timeUpdatedString: String
    var startColor: String?
    var endColor: String?
    var taskID: String?
    var completeType: String?
    var userThanked : String?
    var helpedBy: [String]?
    var taskView: [String]?
    var recentActivity : Bool = false
    var userMovedOutside : Bool = false
    
    

    
    init(userId: String , taskDescription: String, latitude: CLLocationDegrees, longitude: CLLocationDegrees, completed: Bool, timeCreated: Date = Date(), timeUpdated: Date = Date(), taskID : String, recentActivity : Bool, userMovedOutside : Bool ) {
        self.userMovedOutside = userMovedOutside
        self.recentActivity = recentActivity
        self.userId =  userId
        self.taskDescription = taskDescription
        self.latitude = latitude
        self.longitude = longitude
        self.completed = completed
        self.timeCreated = timeCreated
        self.timeUpdated = timeUpdated
        self.taskID = taskID
        self.completeType = ""
        userThanked = ""
        taskView = nil
        
      // self.startColor = startColor
     //  self.endColor = endColor
        
        // create new task object
        // setup firebase database
        ref = FIRDatabase.database().reference()
        
        // setup tasks ref
        tasksRef = ref.child("tasks")
        
        //set up users ref
        userRef = ref.child("users")
        
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
    
    func updateFirebaseTask() {
        // save task to database
        // create new task with user id as identifier
        // create new date formatter
        let dateformatter = DateStringFormatterHelper()
        
        // convert timeCreated and timeUpdated to string
        let updateDate = dateformatter.convertDateToString(date: Date())
        
        let taskDictionary: [String: Any] = [
            "taskDescription": self.taskDescription,
            "timeCreated": self.timeCreatedString,
            "timeUpdated": updateDate,
            "completed": self.completed,
            "startColor": self.startColor ?? "",
            "endColor": self.endColor ?? "",
            "createdby": FIRAuth.auth()?.currentUser?.uid ?? self.userId,
            "taskID": self.taskID!,
            "completeType" : self.completeType ?? "" ,
            "userMovedOutside" : self.userMovedOutside  ,
            "recentActivity" : self.recentActivity,
            "helpedBy" : "" ]
        tasksRef.child(self.taskID!).setValue(taskDictionary)
    }
    
    func save() {
        
         updateFirebaseTask()
        
        //Update Task at user Profile
        updateTasksCreated((FIRAuth.auth()?.currentUser?.uid)!)
        
        // save task location to database with user id as key
        geoFire?.setLocation(CLLocation(latitude:latitude, longitude: longitude), forKey: "\(self.taskID!)") { (error) in
            if (error != nil) {
                print("An error occured: \(String(describing: error))")
            } else {
                print("Saved task location successfully!")
            }
        }
        
    }
    
    func updateTasksCreated(_ userID : String)  {
        userRef.child(userID).child("taskCreated").observeSingleEvent(of: .value, with: { (snapshot) in
            if let arrTasksdetail = snapshot.value as? [String : Any] {
                if var tasks = arrTasksdetail["tasks"] as? [String] {
                    if !tasks.contains(self.taskID!) {
                        tasks.append(self.taskID!)
                        let tasksParticipateUpdate =  ["tasks" : tasks, "count":tasks.count] as [String : Any];
                        // update at server
                        self.userRef.child(userID).child("taskCreated").setValue(tasksParticipateUpdate)
                    }
                }
                else {
                    let tasksParticipateUpdate =  ["tasks" : [self.taskID], "count":1] as [String : Any];
                    // update at server
                    self.userRef.child(userID).child("taskCreated").setValue(tasksParticipateUpdate)
                }
            }
            else {
                let tasksParticipateUpdate =  ["tasks" : [self.taskID], "count":1] as [String : Any];
                // update at server
                self.userRef.child(userID).child("taskCreated").setValue(tasksParticipateUpdate)
            }
        })
    }
    
}
