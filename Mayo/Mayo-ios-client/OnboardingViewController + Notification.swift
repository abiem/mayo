//
//  OnboardingViewController + Notification.swift
//  Mayo-ios-client
//
//  Created by Lakshmi Kodali on 27/12/17.
//  Copyright © 2017 Weijie. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications
import Firebase

extension OnboardingViewController: UNUserNotificationCenterDelegate {
  
  
  // shows notifications when app is in the foreground
  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    
    
    let currentViewController = getCurrentViewController()
    let notificationTitle = notification.request.content.title
    
    // TODO: if current view controller is not nil
    if let viewController = currentViewController {
      
      // if the current user is in main view controller
      // and the user was thanked, show the you were thanked animation
      if viewController is MainViewController && notificationTitle == "You were thanked!" {
        let mainViewController = viewController as! MainViewController
        mainViewController.showUserThankedAnimation()
      }
      
      //if current view controller is in a chat view controller
      if viewController is ChatViewController {
        //if the current chat view controller is the same id as the current notification's id
        // don't show the notification
        
        // get data from notification for the channel id that the notification was sent from
        if let channelId = notification.request.content.userInfo["channelId"] {
          let chatViewController = viewController as! ChatViewController
          let channelIdString = channelId as! String
          
          // if current user is in the same channel as where the notification was sent from
          if let chatChannelId = chatViewController.channelId {
            
            // don't send a message
            if channelIdString == chatChannelId {
              return
            } else {
              // if current user is in a different channel than where the notification was sent from
              // send a system notification to the other channel
              completionHandler([.alert, .badge, .sound])
              return
              
            }
          }
          
        }
        
      }
      else {
        
        // if the user is on the home screen
        // always show the system notification and bring the user to the correct task based on the notification
        completionHandler([.alert, .badge, .sound])
        
      }
      
    }
  }
  
  
  
  // Returns the most recently presented UIViewController (visible)
  func getCurrentViewController() -> UIViewController? {
    
    // If the root view is a navigation controller, we can just return the visible ViewController
    if let navigationController = getNavigationController() {
      
      return navigationController.visibleViewController
    }
    
    // Otherwise, we must get the root UIViewController and iterate through presented views
    if let rootController = UIApplication.shared.keyWindow?.rootViewController {
      
      var currentController: UIViewController! = rootController
      
      // Each ViewController keeps track of the view it has presented, so we
      // can move from the head to the tail, which will always be the current view
      while( currentController.presentedViewController != nil ) {
        
        currentController = currentController.presentedViewController
      }
      return currentController
    }
    return nil
  }
  
  // Returns the navigation controller if it exists
  func getNavigationController() -> UINavigationController? {
    
    if let navigationController = UIApplication.shared.keyWindow?.rootViewController  {
      
      return navigationController as? UINavigationController
    }
    return nil
  }
  
  
  
}
