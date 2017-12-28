//
//  NotificationManager.swift
//  Mayo-ios-client
//
//  Created by Lakshmi Kodali on 27/12/17.
//  Copyright © 2017 Weijie. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

enum NotificationStatus {
  case allowedNotification
  case denied
  case notDetermined
}

func checkStatusOfNotification(_ result:@escaping (_ status:NotificationStatus) ->()) {
  var status:NotificationStatus = .denied
  let current = UNUserNotificationCenter.current()
  
  current.getNotificationSettings(completionHandler: { (settings) in
    if settings.authorizationStatus == .notDetermined {
      status = .notDetermined
      result(status)
    }
    
    if settings.authorizationStatus == .denied {
      status = .denied
      result(status)
    }
    
    if settings.authorizationStatus == .authorized {
      status = .allowedNotification
      result(status)
    }
  })

}

func requestForNotification() {
  checkNotificationAuth()
}

func checkNotificationAuth() -> Void {
    if #available(iOS 10.0, *){
      
      // Register for remote notifications. This shows a permission dialog on first run, to
      // show the dialog at a more appropriate time move this registration accordingly.
      // [START register_for_notifications]
      if #available(iOS 10.0, *) {
        // For iOS 10 display notification (sent via APNS)
       // UNUserNotificationCenter.current().delegate = UIApplication.shared as? UNUserNotificationCenterDelegate
        let _: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { (granted, error) in
        })
      } else {
        let settings: UIUserNotificationSettings =
          UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
        UIApplication.shared.registerUserNotificationSettings(settings)
      }
      
      UIApplication.shared.registerForRemoteNotifications()
      // [END register_for_notifications]
      
    } else {
      
      // TODO: double check
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      UIApplication.shared.registerUserNotificationSettings(settings)
    }
    
    UIApplication.shared.registerForRemoteNotifications()
    
  
}
