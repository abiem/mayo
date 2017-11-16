//
//  PushNotificationManager.swift
//  Mayo-ios-client
//
//  Created by star on 8/26/17.
//  Copyright © 2017 abiem. All rights reserved.
//

import Foundation
import Alamofire

class PushNotificationManager {
    
    // TODO: send notification to the topic for specific channel id
    static func sendNotificationToTopic(channelId: String, topic: String, currentUserId: String) {
        
        // setup alamofire url
        let fcmURL = "https://fcm.googleapis.com/fcm/send"
        let parameters: Parameters = [
            "to": "/topics/\(channelId)",
            "priority": "high",
            "notification": [
                "body": "Someone posted in \(topic)",
                "title": "New Message Posted",
                "content_available": true,
                "sound": "default"
            ],
            "data": [
                "sender_id": "\(currentUserId)",
                "channelId": "\(channelId)",
                "task_description": "\(topic)",
                "notification_type": "\(Constants.NOTIFICATION_MESSAGE)"
            ]
        ]
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization": "key=\(Constants.FIREBASE_CLOUD_SERVER_KEY)"
        ]
        
        Alamofire.request(fcmURL, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseJSON { response in
                print("Message Notification")
                print(response.request as Any)  // original URL request
                print(response.response as Any) // URL response
                print(response.result.value as Any)   // result of response serialization
                
        }
        
        print("notification posted")
    }
    
    static func sendNotificationToDeviceForMessage(device:String ,channelId: String, topic: String, currentUserId: String) {
        
        // setup alamofire url
        let fcmURL = "https://fcm.googleapis.com/fcm/send"
        let parameters: Parameters = [
            "to": "\(device)",
            "priority": "high",
            "notification": [
                "body": "Someone posted in \(topic)",
                "title": "New Message Posted",
                "content_available": true,
                "sound": "default"
            ],
            "data": [
                "sender_id": "\(currentUserId)",
                "channelId": "\(channelId)",
                "task_description": "\(topic)",
                "notification_type": "\(Constants.NOTIFICATION_MESSAGE)"
            ]
        ]
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization": "key=\(Constants.FIREBASE_CLOUD_SERVER_KEY)"
        ]
        
        Alamofire.request(fcmURL, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseJSON { response in
                print("Message Notification")
                print(response.request as Any)  // original URL request
                print(response.response as Any) // URL response
                print(response.result.value as Any)   // result of response serialization
                
        }
        
        print("notification posted")
    }
    
    static func sendYouWereThankedNotification(deviceToken: String, _ pTaskDescription: String) {
        
        if deviceToken.isEmpty || deviceToken.characters.count == 0 {
            return
        }
        
        // setup alamofire url
        let fcmURL = "https://fcm.googleapis.com/fcm/send"
        print("device token \(deviceToken.characters.count) \(deviceToken)")
        // add application/json and add authorization key
        let parameters: Parameters = [
            "to": "\(deviceToken)",
            "priority": "high",
            "notification": [
                "body": "🤜🏻🤛🏻The quest \(pTaskDescription) was completed and you were thanked!",
                "title": "You were thanked!",
                "sound": "default"
            ],
            "data": [
                "notification_type": "\(Constants.NOTIFICATION_WERE_THANKS)"
            ]
        ]
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization": "key=\(Constants.FIREBASE_CLOUD_SERVER_KEY)"
        ]
        Alamofire.request(fcmURL, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseJSON { response in
                print("Message Notification")
                print(response.request as Any)  // original URL request
                print(response.response as Any) // URL response
                print(response.result.value as Any)   // result of response serialization
        }
    }
    
    
    static func sendNearbyTaskNotification(deviceToken: String, taskID : String) {
        
        if deviceToken.isEmpty || deviceToken.characters.count == 0 {
            return
        }
        
        // setup alamofire url
        let fcmURL = "https://fcm.googleapis.com/fcm/send"
        print("device token \(deviceToken.characters.count) \(deviceToken)")
        // add application/json and add authorization key
        let parameters: Parameters = [
            "to": "\(deviceToken)",
            "priority": "high",
            "notification": [
                "body": "Someone has a new quest nearby",
                "title": "New quest available",
                "sound": "default"
            ],
            "data": [
                "notification_type": "\(Constants.NOTIFICATION_NEARBY_TASK)",
                "taskID" : taskID
            ]
        ]
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization": "key=\(Constants.FIREBASE_CLOUD_SERVER_KEY)"
        ]
        Alamofire.request(fcmURL, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseJSON { response in
                print("Nearby Task Notification")
                print(response.request as Any)  // original URL request
                print(response.response as Any) // URL response
                print(response.result.value as Any)   // result of response serialization
        }
    }

    static func sendNotificationToTopicOnCompletion(channelId: String, taskMessage: String) {
        
        // setup alamofire url
        let fcmURL = "https://fcm.googleapis.com/fcm/send"
        
        // add application/json and add authorization key
        let parameters: Parameters = [
            "to": "/topics/\(channelId)",
            "priority": "high",
            "notification": [
                "body": "'The quest \(taskMessage) was completed",
                "title": "Nearby quest Completed",
                "content_available": true,
                "sound": "default"
            ],
            "data": [
                "channelId": "\(channelId)",
                "notification_type": "\(Constants.NOTIFICATION_TOPIC_COMPLETED)"
            ]
        ]
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization": "key=\(Constants.FIREBASE_CLOUD_SERVER_KEY)"
        ]
        
        Alamofire.request(fcmURL, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseJSON { response in
                print("Completed Notification")
                print(response.request as Any)  // original URL request
                print(response.response as Any) // URL response
                print(response.result.value as Any)   // result of response serialization
        }
        
    }
    
    
    static func sendNotificationToDevice(deviceToken: String, channelId: String, taskMessage: String) {
        
        // setup alamofire url
        let fcmURL = "https://fcm.googleapis.com/fcm/send"
        
        // add application/json and add authorization key
        let parameters: Parameters = [
            "to": "\(deviceToken)",
            "priority": "high",
            "notification": [
                "body": "The quest \(taskMessage) was completed",
                "title": "Nearby quest Completed",
                "content_available": true,
                "sound": "default"
            ],
            "data": [
                "channelId": "\(channelId)",
                "notification_type": "\(Constants.NOTIFICATION_TOPIC_COMPLETED)"
            ]
        ]
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization": "key=\(Constants.FIREBASE_CLOUD_SERVER_KEY)"
        ]
        
        Alamofire.request(fcmURL, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseJSON { response in
                print("Completed Notification")
                print(response.request as Any)  // original URL request
                print(response.response as Any) // URL response
                print(response.result.value as Any)   // result of response serialization
        }    }
}
