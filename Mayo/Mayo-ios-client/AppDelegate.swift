//
//  AppDelegate.swift
//  Mayo-ios-client
//
//  Created by abiem  on 4/8/17.
//  Copyright © 2017 abiem. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation
import UserNotifications
import IQKeyboardManagerSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var ref: FIRDatabaseReference!
    var mainVC: MainViewController!
    let gcmMessageIDKey = "gcm.message_id"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        IQKeyboardManager.sharedManager().enable = true

        // setup firebase
        FIRApp.configure()

        NotificationCenter.default.addObserver(self, selector: #selector(tokenRefreshNotification(_:)), name: NSNotification.Name.firInstanceIDTokenRefresh, object: nil)
        
        // For iOS 10 data message (sent via FCM)
        FIRMessaging.messaging().remoteMessageDelegate = OnboardingNotifcationsViewController()
        UNUserNotificationCenter.current().delegate = OnboardingNotifcationsViewController()

        
        // log in user annonymously
        FIRAuth.auth()?.signInAnonymously() { (user, error) in
            if error != nil {
                print("an error occured during auth")
                return
            }
            
            // user is signed in
            let uid = user!.uid
            let defaults = UserDefaults.standard
            defaults.setValue(uid, forKey: "currentUserId")
            print("userid: \(uid)")
            
            self.ref = FIRDatabase.database().reference()
            self.ref.child("users/\(uid)").observeSingleEvent(of: .value, with: { (snapshot) in
                
                // check if the current user has a score set
                if snapshot.hasChild("score"){
                    let value = snapshot.value as? NSDictionary
                    let score = value?["score"] as? Int //?? 0
                    print("user already has a score of \(String(describing: score)))")
                    
                    // if current user does not have a score set
                } else {
                    // set score to 0
                    print("user does not have points yet")
                    self.ref.child("users/\(uid)/score").setValue(0)
                    print("user score is set to 0")
                }
            })
            
            // check if MainViewController user init.
            if self.mainVC != nil {
                self.mainVC.initUserAuth()
            }
        }
        
        // check if user has gone through the onboarding
        // and that the user has given access to
        // notifications and location
        let userDefaults = UserDefaults.standard
        let onboardingHasBeenShown = userDefaults.bool(forKey: "onboardingHasBeenShown")
        
        if onboardingHasBeenShown {
            // if the user has given access to all of the authorizations
            // present main
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            mainVC = storyboard.instantiateViewController(withIdentifier: "MainViewController") as! MainViewController
            let navViewController = UINavigationController(rootViewController: mainVC)
            self.window?.rootViewController = navViewController
            
        } else {
            // else present authorization
        }
        return true
    }


    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        
        // hide keyboard if its on the screen
        self.window?.endEditing(true)
        
        // disconnect from firebase messaging.
        FIRMessaging.messaging().disconnect()
        print("Disconnected from FCM.")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // [START receive_message]
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        FIRMessaging.messaging().appDidReceiveMessage(userInfo)
        if let aps = userInfo["aps"] as? NSDictionary {
            if let _ = aps["alert"] as? NSDictionary {
                if let notification_type = userInfo["notification_type"] {
                    
                    print("notification_type = \(notification_type)")
                    
                    switch Int(notification_type as! String)! {
                        
                    // Process Message push notificaton.
                    case Constants.NOTIFICATION_MESSAGE:
                        
                        print("Message Push Notification Clicked")
                        
                        if let senderId = userInfo["sender_id"] as? String {
                            if let currentUserId = FIRAuth.auth()?.currentUser?.uid {
                                if senderId == currentUserId {
                                    return
                                }
                                else {
                                    processMessageNotification(userInfo: userInfo)
                                }
                            }
                            else {
                                FIRAuth.auth()?.signInAnonymously() { (user, error) in
                                    if error != nil {
                                        print("an error occured during auth")
                                        return
                                    }
                                    
                                    let currentUserId = FIRAuth.auth()?.currentUser?.uid
                                    if senderId == currentUserId {
                                        return
                                    }
                                    else {
                                        self.processMessageNotification(userInfo: userInfo)
                                    }
                                }
                            }
                        }
                        
                        break
                        
                    // Process topic complete push notification.
                    case Constants.NOTIFICATION_TOPIC_COMPLETED:
                        
                        print("Task Completed Push Notification Clicked")
                        
                        if let channelId = userInfo["channelId"] {
                            print("channelId: \(channelId)")
                            FIRMessaging.messaging().unsubscribe(fromTopic: "/topics/\(channelId)")
                        }
                        break
                        
                    // Process Thanks push notification.
                    case Constants.NOTIFICATION_WERE_THANKS:
                        
                        print("Thanks Push Notification Clicked")
                        
                        if self.mainVC != nil {
                            self.mainVC.showUserThankedAnimation()
                        }
                        break
                    
                    default:
                        break
                    }
                }
            }
        }
        
        print("received message in delegate")
        print("received notification \(userInfo)")
        //completionHandler(UIBackgroundFetchResult.newData)
    }
    
    func processMessageNotification(userInfo: [AnyHashable : Any]) {
        
        let state = UIApplication.shared.applicationState
        if state == .active {

            // foreground
            return
        }
        
        //Get Current ViewController.
        let currentViewController = getCurrentViewController()
        if let channelId = userInfo["channelId"] {
            if let task_description = userInfo["task_description"] {
                
                var chatVC: ChatViewController!
                var needToPush = false
                if (currentViewController is MainViewController) {
                    
                    //Move to ChatViewController.
                    chatVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "chatViewController") as! ChatViewController
                    needToPush = true
                }
                else if (currentViewController is ChatViewController) {
                    chatVC = currentViewController as? ChatViewController
                }
                
                if chatVC == nil {
                    chatVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "chatViewController") as! ChatViewController
                    needToPush = true
                }
                
                chatVC.channelTopic = task_description as? String
                chatVC.channelId = channelId as? String
                ref = FIRDatabase.database().reference()
                let channelsRef = ref?.child("channels")
                
                if let chatChannelRef = channelsRef?.child(channelId as! String) {
                    chatVC.channelRef = chatChannelRef
                    if needToPush == true {
                        self.getNavigationController()?.pushViewController(chatVC, animated: true)
                    }
                    else {
                        chatVC.reloadChat()
                    }
                    
                } else {
                    FIRAuth.auth()?.signInAnonymously() { (user, error) in
                        if error != nil {
                            print("an error occured during auth")
                            return
                        }
                        
                        self.ref = FIRDatabase.database().reference()
                        let channelsRef = self.ref?.child("channels")
                        if let chatChannelRef = channelsRef?.child(channelId as! String) {
                            chatVC.channelRef = chatChannelRef
                            if needToPush == true {
                                self.getNavigationController()?.pushViewController(chatVC, animated: true)
                            }
                            else {
                                chatVC.reloadChat()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        // send device token to firebase messages server
        FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: FIRInstanceIDAPNSTokenType.sandbox)
       
        //FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: FIRInstanceIDAPNSTokenType.prod)
        
        #if PROD_BUILD
            FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: .prod)
        #else
            FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: .sandbox)
        #endif
        
        var readableToken: String = ""
        for i in 0..<deviceToken.count {
            readableToken += String(format: "%02.2hhx", deviceToken[i] as CVarArg)
        }
        print("Received an APNs device token: \(readableToken)")
        
        // update the user notification token for current user
        updateNotificationTokenForCurrentUser()
    }
    
    func updateNotificationTokenForCurrentUser() {
        
        if let refreshedToken = FIRInstanceID.instanceID().token() {
            
            print("InstanceID token: \(refreshedToken)")
            
            // get references to save user token
            
            if let userId = FIRAuth.auth()?.currentUser?.uid {
                
                // save device token for push notifications
                ref.child("users/\(userId)/deviceToken").setValue(refreshedToken)
                
            }
            
        }
        
    }
    
    func tokenRefreshNotification(_ notification: Notification) {
        
        // update the notification token for the current user
        updateNotificationTokenForCurrentUser()
        
        // Connect to FCM since connection may have failed when attempted before having a token.
        connectToFcm()
    }

    func connectToFcm() {
        // Won't connect since there is no token
        guard FIRInstanceID.instanceID().token() != nil else {
            return
        }
        
        // Disconnect previous FCM connection if it exists.
        FIRMessaging.messaging().disconnect()
        FIRMessaging.messaging().connect { (error) in
            if error != nil {
                print("Unable to connect with FCM. \(error?.localizedDescription ?? "")")
            } else {
                print("Connected to FCM.")
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(error)
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


// [START ios_10_message_handling]
@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
    
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        // Change this to your preferred presentation option
        completionHandler([])
    }
}


extension AppDelegate : FIRMessagingDelegate {
    
    public func applicationReceivedRemoteMessage(_ remoteMessage: FIRMessagingRemoteMessage)
    {
        print("Received data message: \(remoteMessage.appData)")
    }
}
