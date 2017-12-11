//
//  Global.swift
//  Mayo-ios-client
//
//  Created by star on 8/26/17.
//  Copyright © 2017 abiem. All rights reserved.
//

struct Constants {
    static let FIREBASE_CLOUD_SERVER_KEY = "AAAAYgVZ9lU:APA91bExQ_X8TFudFkv5_5VJ9E70YQ6uB6hlZgkQENBNCOOZl8e_EHsD-WUkGQ2pFz78qZwLtwPvA_kJRNJfYK6r_tpANKwrOn7ZJeeVmCoJBLyO-aqOPQYEncPD05-UleyFfkiVYsPh"
    
    static let NOTIFICATION_MESSAGE = 0
    static let NOTIFICATION_WERE_THANKS = 1
    static let NOTIFICATION_TOPIC_COMPLETED = 2
    static let NOTIFICATION_NEARBY_TASK = 3
    
    static let DEFAULT_LAT = 0.0 //47.612441
    static let DEFAULT_LNG = 0.0 //-122.337463
    
    static let THANKS_ANIMATION_DURATION = 5.0
    static let PENDING_TASKS = "PendingTask"
    static let LOCATION = "location"
    
    static let FONT_NAME = "SanFranciscoText-Regular"
    
    static let STATUS_FOR_THANKED = "Owner marked as done and the people all thanked for"
    static let STATUS_FOR_NOT_HELPED = "Owner marked as done and no one helped"
    static let STATUS_FOR_TIME_EXPIRED = "Expired due to time limit"
    static let STATUS_FOR_MOVING_OUT = "Expired due to moving out of area"
    
    static let sLOCATION_ERROR = "Oh oh!We need your help with location to help us help you. You can enable location for Mayo in Settings"
    static let sTASK_EXPIRED_ERROR = "The quest you're looking for has completed"
    
    //Static ID
    static let FAKE_USER_ID = "fakeUser"
    
    // onboarding constants for standard user defaults.
    static let ONBOARDING_TASK1_VIEWED_KEY = "onboardingTask1Viewed"
    static let ONBOARDING_TASK2_VIEWED_KEY = "onboardingTask2Viewed"
    static let ONBOARDING_TASK3_VIEWED_KEY = "onboardingTask3Viewed"
    
    // array of color hex colors for chat bubbles
    static let chatBubbleColors = [
        "C2C2C2", // task owner's bubble color gray
        "08BBDB",
        "FC8FA3",
        "9CD72F",
        "ED801F",
        "B664C4",
        "4A4A4A",
        "4FB5B2",
        "2F96FF",
        "E86D5D",
        "1DAE73",
        "AC664C",
        "508FBC",
        "BCCB4C",
        "7C3EC1",
        "D36679",
        "5AC7CF",
        "CAA63C"
    ]
    
}

enum locationIconTime : Int {
    case first = 60  // active users
    case second = 120
    case third = 180
    case fourth = 240
    case fifth = 300
    case sixth = 360 // in active users
}


