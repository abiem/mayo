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
            self.alertView?.showWarning("No Internet Connection", subTitle: "", duration: 0)
        }
        reachabilityManager?.listener = { status in
            
            switch status {
                
            case .notReachable:
                print("The network is not reachable")
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                self.alertView?.showWarning("No Internet Connection", subTitle: "", duration: 0)
                
            case .unknown :
                self.alertView?.hideView()
                print("It is unknown whether the network is reachable")
                
            case .reachable(.ethernetOrWiFi):
                self.alertView?.hideView()
                print("The network is reachable over the WiFi connection")
                
            case .reachable(.wwan):
                self.alertView?.hideView()
                print("The network is reachable over the WWAN connection")
                
            }
        }
        reachabilityManager?.startListening()
    }
    
    func isReachable() -> Bool {
        return reachabilityManager?.isReachable ?? false
    }
}
