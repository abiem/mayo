//
//  OnboardingLocationsViewController.swift
//  Mayo-ios-client
//
//  Created by abiem  on 4/16/17.
//  Copyright © 2017 abiem. All rights reserved.
//

import UIKit
import CoreLocation
import AVKit
import AVFoundation
import Firebase


class OnboardingLocationsViewController: UIViewController {
    
    var locationManager: CLLocationManager!
    var askLocationServices = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        playVideo()
    FIRDatabase.database().reference().child("users").child((FIRAuth.auth()?.currentUser?.uid)!).child("isDemoTaskShown").observeSingleEvent(of: .value, with: { (snapshot) in
            if let isIntroTasksDone = snapshot.value as? Bool {
                if isIntroTasksDone == true {
                    let defaults = UserDefaults.standard
                    defaults.set(false, forKey: Constants.ONBOARDING_TASK1_VIEWED_KEY)
                    defaults.set(false, forKey: Constants.ONBOARDING_TASK2_VIEWED_KEY)
                    defaults.set(false, forKey: Constants.ONBOARDING_TASK3_VIEWED_KEY)
                }
            }
        })
    }
    
    private func playVideo() {
        
        if let path = Bundle.main.path(forResource: "fux03", ofType: "mp4") {
            
            let player = AVPlayer(url: URL(fileURLWithPath: path))
            let playerController = AVPlayerViewController()
            
            playerController.player = player
            playerController.showsPlaybackControls = false
            
            self.addChildViewController(playerController)
            self.view.addSubview(playerController.view)
            playerController.view.frame = self.view.frame
            
            player.play()
        } else {
            print("error, fux video not found")
        }
    }

    
//    // check if location is authorized
//    func checkForAuthorization() {
//        
//        if CLLocationManager.locationServicesEnabled() {
//            switch(CLLocationManager.authorizationStatus()) {
//                case .notDetermined, .restricted, .denied:
//                    print("No access")
//                case .authorizedAlways, .authorizedWhenInUse:
//                // if location authorized
//                // go to main viewcontroller
//                    print("Access")
//            }
//            
//            
//        } else {
//            print("Location services are not enabled")
//        }
//        
//        
//    }
    
    func gotoMainViewController() {
        let MainViewController = self.storyboard?.instantiateViewController(withIdentifier: "MainViewController") as! MainViewController
        let navViewController = UINavigationController(rootViewController:MainViewController)
        self.present(navViewController, animated: true, completion: nil)
        
        // set onboarding has been shown to true
        // inside user defaults
        let userDefaults = UserDefaults.standard
        userDefaults.set(true, forKey: "onboardingHasBeenShown")

    }
    
    func askForLocationAuth() {
        // get location authorization
        // display user location
        print("askForLocationAuth hit")
        
        if CLLocationManager.locationServicesEnabled() {
            
            // if location services are enables, ask for 
            // access to location
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.allowsBackgroundLocationUpdates = true
            
            if CLLocationManager.authorizationStatus() != .authorizedAlways {
                locationManager.requestAlwaysAuthorization()
            } else if CLLocationManager.locationServicesEnabled() {
                locationManager.startUpdatingLocation()
            }
            
        }
        else {
            gotoMainViewController()
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    
}

extension OnboardingLocationsViewController: AVPlayerViewControllerDelegate {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let location = touch.location(in: self.view)
        
        if location.y > (self.view.bounds.height * 3/4) {
            // ask for access to notifications
            // go to the next screen
            print("3rd video pressed")
            
            if askLocationServices == false {
                
                // first ask for location authorization
                askForLocationAuth()
                askLocationServices = true
            }

        }
    }
}

extension OnboardingLocationsViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        var shouldIAllow = false
        var locationStatus = ""
        
        switch status {
            
        case CLAuthorizationStatus.restricted:
            locationStatus = "Restricted Access to location"
        case CLAuthorizationStatus.denied:
            locationStatus = "User denied access to location"
        case CLAuthorizationStatus.notDetermined:
            locationStatus = "Status not determined"
            return
        default:
            locationStatus = "Allowed to location Access"
            shouldIAllow = true
        }
        
        if (shouldIAllow == true) {
            NSLog("Location to Allowed")
            
            // Start location services
            locationManager.startUpdatingLocation()
            gotoMainViewController()
            
        } else {
            NSLog("Denied access: \(locationStatus)")
            gotoMainViewController()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError")
        gotoMainViewController()
    }
}


