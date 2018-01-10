//
//  MainViewController+TaskDelegate.swift
//  Mayo-ios-client
//
//  Created by Lakshmi Kodali on 10/01/18.
//  Copyright © 2018 Weijie. All rights reserved.
//

import Foundation

extension MainViewController : taskDelegate {
  
  
  func taskUpdateFailed(_ error : Error?) {
    if error == nil {
    CMAlertController.sharedInstance.showAlert(nil, "Something Went Wrong", ["Ok"], { (sender) in
      UserDefaults.standard.set(nil, forKey: Constants.PENDING_TASKS)
      self.currentUserTaskSaved = false
      self.carouselView.reloadData()
    })
  } else {
  //Saving of Task
    let currentUserTask = self.tasks[0] as! Task
  var dicTask = Dictionary<String, Any>()
  dicTask["userId"] = currentUserTask.userId
  dicTask["taskDescription"] = currentUserTask.taskDescription
  dicTask["latitude"] = currentUserTask.latitude
  dicTask["startColor"] = currentUserTask.startColor
  dicTask["endColor"] = currentUserTask.endColor
  dicTask["longitude"] = currentUserTask.longitude
  dicTask["completed"] = currentUserTask.completed
  dicTask["timeCreated"] = currentUserTask.timeCreated
  dicTask["timeUpdated"] = currentUserTask.timeUpdated
  dicTask["taskID"] = currentUserTask.taskID
  dicTask["recentActivity"] = currentUserTask.recentActivity
  dicTask["userMovedOutside"] = currentUserTask.userMovedOutside
  
  // encode Task for saving
  let data = NSKeyedArchiver.archivedData(withRootObject: dicTask)
  UserDefaults.standard.set(data, forKey: Constants.PENDING_TASKS)
  }
  
  }
}
