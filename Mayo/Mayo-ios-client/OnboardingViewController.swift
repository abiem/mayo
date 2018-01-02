//
//  OnboardingViewController.swift
//  Mayo-ios-client
//
//  Created by Lakshmi Kodali on 20/12/17.
//  Copyright © 2017 Weijie. All rights reserved.
//

import UIKit
import iCarousel
import Firebase
import CoreLocation

class OnboardingViewController: UIViewController {
  //Outlets
  @IBOutlet weak var mBackgroundAnimation: UIImageView!
  @IBOutlet weak var mCarousel: iCarousel!
  @IBOutlet weak var mImageView: UIImageView!
  // Instance
  var playingThanksAnim = false
  var locationManager: CLLocationManager!
  let mThanksImageListArray: NSMutableArray = []
  let mSecondPinImageListArray: NSMutableArray = []
  let mThirdPinImageListArray: NSMutableArray = []
  //rotation key animation
  let kRotationAnimationKey = "com.mayo.rotationanimationkey"
  
    override func viewDidLoad() {
        super.viewDidLoad()
      sequenceOfThanks()
      sequenceOfSecondPin()
      sequenceOfThirdPin()

      if FIRAuth.auth()?.currentUser?.uid == nil {
        FIRAuth.auth()?.signInAnonymously() { (user, error) in
          if error != nil {
            print("an error occured during auth")
            return
          }
          self.checkFakeTaskStatus()
        }
      } else {
       checkFakeTaskStatus()
      }
      
      mCarousel.type = iCarouselType.linear
      mCarousel.isPagingEnabled = true
      mCarousel.isScrollEnabled = false
      mCarousel.bounces = true
      mCarousel.bounceDistance = 0.2
      mCarousel.scrollSpeed = 1.0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
      
    }
  
  
  func checkFakeTaskStatus() {
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
  //Mark :- location Permission
  func askForLocationAuth() {
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
  
  //Mark :- Navigate
  func gotoMainViewController() {
    let MainViewController = self.storyboard?.instantiateViewController(withIdentifier: "MainViewController") as! MainViewController
    let navViewController = UINavigationController(rootViewController:MainViewController)
    self.present(navViewController, animated: true, completion: nil)
    
    // set onboarding has been shown to true
    // inside user defaults
    let userDefaults = UserDefaults.standard
    userDefaults.set(true, forKey: "onboardingHasBeenShown")
    
  }
  
  func sequenceOfThanks() {
    DispatchQueue.global(qos: .background).async {
      for countValue in 1...51
      {
        let imageName : String = "fux00\(countValue).png"
        let image  = UIImage(named:imageName)
        self.mThanksImageListArray.add(image!)
      }
    }
  }
  
  func sequenceOfSecondPin() {
    DispatchQueue.global(qos: .background).async {
      for countValue in 1...71
      {
        let imageName : String = "fatpin1.00\(countValue).png"
        let image  = UIImage(named:imageName)
        self.mSecondPinImageListArray.add(image!)
      }
    }
  }
  
  func sequenceOfThirdPin() {
    DispatchQueue.global(qos: .background).async {
      for countValue in 1...80
      {
        let imageName : String = "fatpin2.00\(countValue).png"
        let image  = UIImage(named:imageName)
        self.mThirdPinImageListArray.add(image!)
      }
    }
  }
  
  //Mark :- Ripple Animation
  func showRippleAnimation(_ pCenterImage:UIImage?,_ pBackgroundImage: UIImage) {
    self.mImageView.contentMode = .center
    self.mImageView.image = pCenterImage
    self.mBackgroundAnimation.image = pBackgroundImage
    self.mBackgroundAnimation.transform = CGAffineTransform.identity
    self.mBackgroundAnimation.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
    UIView.commitAnimations()
    UIView.animate(withDuration: Constants.THANKS_RIPPLE_ANIMATION_DURATION, delay: 0, options: [.repeat, .autoreverse, .curveEaseInOut], animations: {
      self.mBackgroundAnimation.transform = CGAffineTransform(scaleX: 5, y: 5)
    }, completion: { (completed) in
      self.mBackgroundAnimation.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)

    })
  }
  
  //Mark :- Thanks Image
  func showUserThankedAnimation() {
    if playingThanksAnim { return }
    
     self.mImageView.contentMode = .scaleAspectFit
    flareAnimation(view: self.mBackgroundAnimation, duration: Constants.THANKS_ANIMATION_DURATION)
    self.mImageView.animationImages = self.mThanksImageListArray as? [UIImage]
    self.mImageView.animationDuration = Constants.THANKS_ANIMATION_DURATION
    self.mImageView.animationRepeatCount = 1
    self.mImageView.startAnimating()
    mBackgroundAnimation.startAnimating()
    
    }
  
  func showSecondPinAnimation() {
    self.mImageView.contentMode = .scaleAspectFit
    self.mBackgroundAnimation.image = nil;
    self.mImageView.animationImages = self.mSecondPinImageListArray as? [UIImage]
    self.mImageView.animationDuration = Constants.SECOND_PIN_ANIMATION_DURATION
    self.mImageView.animationRepeatCount = 0
    self.mImageView.startAnimating()
    
  }
  
  func showThirdPinAnimation() {
    self.mImageView.contentMode = .scaleAspectFit
    self.mBackgroundAnimation.image = nil;
    self.mImageView.animationImages = self.mThirdPinImageListArray as? [UIImage]
    self.mImageView.animationDuration = Constants.THIRD_PIN_ANIMATION_DURATION
    self.mImageView.animationRepeatCount = 0
    self.mImageView.startAnimating()
    
  }
  
    
  
  //Start Flare Animation for thanks
  func flareAnimation(view: UIView, duration: Double = 1) {
    mBackgroundAnimation.image = #imageLiteral(resourceName: "flareImage")
    if view.layer.animation(forKey: kRotationAnimationKey) == nil {
      let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
      rotationAnimation.fromValue = 0.0
      rotationAnimation.toValue = Float(.pi * 2.0)
      rotationAnimation.duration = duration
      rotationAnimation.repeatCount = Float.infinity
      view.layer.add(rotationAnimation, forKey: kRotationAnimationKey)
    }
  }
  
  func stopAnimationAnimation() {
    mBackgroundAnimation.layer.removeAllAnimations()
    mImageView.stopAnimating()
    self.mImageView.animationImages = nil
    mImageView.image = nil
    mBackgroundAnimation.image = nil
    playingThanksAnim = false
  }
  
}
