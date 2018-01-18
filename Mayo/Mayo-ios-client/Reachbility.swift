//
//  Reachbility.swift
//  Mayo-ios-client
//
//  Created by Lakshmi Kodali on 23/10/17.
//  Copyright © 2017 Weijie. All rights reserved.
//

import UIKit
import Alamofire
import SCLAlertView

class Reachbility: NSObject {
    
    static let sharedInstance = Reachbility()
    let alertView : SCLAlertView?
    
    private override init() {
        let appearance = SCLAlertView.SCLAppearance(
            showCloseButton: false
        )
        alertView = SCLAlertView(appearance: appearance)
        
    }
    
    let reachabilityManager = Alamofire.NetworkReachabilityManager(host: "www.apple.com")
    
    func startNetworkReachabilityObserver() {
        
        if !(reachabilityManager?.isReachable)! {
            print("The network is not reachable")
          CMAlertController.sharedInstance.showAlert(nil, "Oops can't connect to the Internet.", ["OK"], nil)
        }
        reachabilityManager?.listener = { status in
            
            switch status {
                
            case .notReachable:
                print("The network is not reachable")
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
              CMAlertController.sharedInstance.showAlert(nil, "Oops can't connect to the Internet.", ["OK"], nil)
              
            case .unknown :
                self.alertView?.hideView()
                //CMAlertController.sharedInstance.dismissController()
                print("It is unknown whether the network is reachable")
                
            case .reachable(.ethernetOrWiFi):
                //CMAlertController.sharedInstance.dismissController()
                print("The network is reachable over the WiFi connection")
                
            case .reachable(.wwan):
                //CMAlertController.sharedInstance.dismissController()
                print("The network is reachable over the WWAN connection")
                
            }
        }
        reachabilityManager?.startListening()
    }
    
    func isReachable() -> Bool {
        return reachabilityManager?.isReachable ?? false
    }
}
