//
//  ViewController.swift
//  Mayo-ios-client
//
//  Created by abiem  on 4/8/17.
//  Copyright © 2017 abiem. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Firebase
import GeoFire
import iCarousel
import SwiftMoment
import UserNotifications
import Alamofire
import AVKit
import AVFoundation
import Cluster

class MainViewController: UIViewController {
  
  @IBOutlet weak var mCarouselHeight: NSLayoutConstraint!
  @IBOutlet weak var carouselView: iCarousel!
  @IBOutlet weak var mapView: MKMapView!
  var lastUpdatedTime : Date?
  var pointsLabel: UILabel!
  var thanksAnimImageView: UIImageView!
  var flareAnimImageView: UIImageView!
  var playingThanksAnim = false
  var canCreateNewtask = false
  var completedTask:Task?
  var heightShadow = 0
  //user Task ID
  var userTaskId :String?
  // tags and constants for subviews
  let COMPLETION_VIEW_TAG = 98
  let USERS_HELPED_BUTTON_TAG = 99
  let NO_USERS_HELPED_BUTTON_TAG = 100
  let CURRENT_USER_TEXTVIEW_TAG = 101
  let POINTS_GRADIENT_VIEW_TAG = 102
  let POINTS_GRADIENT_VIEW_LABEL_TAG = 103
  let POST_NEW_TASK_BUTTON_TAG = 104
  let POINTS_PROFILE_VIEW_TAG = 105
  let CURRENT_USER_CANCEL_BUTTON = 106
  let LOADER_VIEW = 107
  
  // z index for map annotations
  let ANNOTATION_TOP_INDEX = 7.0
  let CLUSTER_TASK_ANNOTATION_Z_INDEX = 6.0
  let FOCUS_MAP_TASK_ANNOTATION_Z_INDEX = 4.0
  let STANDARD_MAP_TASK_ANNOTATION_Z_INDEX = 3.0
  let STANDARD_MAP_EXPIRE_TASK_ANNOTATION_Z_INDEX = 5.0
  
  // constants for onboarding tasks
  let ONBOARDING_TASK_1_DESCRIPTION = "Helping people around you is simple. Swipe the cards or look around the map."
  let ONBOARDING_TASK_2_DESCRIPTION = "So our AI is a bit bored, help us by sending a message!"
  let ONBOARDING_TASK_3_DESCRIPTION = "Need help? Swipe to the very left to setup a help quest."
  
  //rotation key animation
  let kRotationAnimationKey = "com.mayo.rotationanimationkey"
  
  // save the last index for the carousel view
  var lastCardIndex: Int?
  
  // constants for time
  let SECONDS_IN_HOUR = 3600
  
  // constants for time
  let SECONDS_IN_DAY = 86400
  
  //Contant Time for location update
  let LOCATION_UPDATE_IN_SECOND = 600
  
  //Constant minimum Chat history
  let CHAT_HISTORY = 5
  
  // flag to check if swiped left to add new item
  var newItemSwiped = false
  
  // chat channels
  var chatChannels: [String] = []
  
  // nearby users.
  var nearbyUsers: [String] = []
  
  // boolean check for if keyboard is on screen
  var keyboardOnScreen = false
  
  //Check Push Notification
  var mShowNotification = true
  
  // query distance for getting nearby tasks and users in meters
  let queryDistance = 200.0
  
  // current user uid
  var currentUserId: String?
  
  // checks if the current user saved current task
  var currentUserTaskSaved = false
  
  // user location coordinates
  var userLatitude: CLLocationDegrees?
  var userLongitude: CLLocationDegrees?
  
  // users to thank array
  var usersToThank: [String:Bool] = [:]
  
  // firebase ref
  var ref: FIRDatabaseReference?
  
  var usersRef: FIRDatabaseReference?
  var currentUserHandle: FIRDatabaseHandle?
  var mCurrentUserTaskActivity : FIRDatabaseHandle?
  
  var taskViewRef: FIRDatabaseReference?
  
  var tasksRef:FIRDatabaseReference?
  var channelsRef: FIRDatabaseReference?
  
  var tasksExpireObserver: FIRDatabaseHandle?
  var tasksRefHandle: FIRDatabaseHandle?
  var tasksCircleQuery : GFCircleQuery?
  var usersCircleQuery : GFCircleQuery?
  var tasksCircleQueryHandle: FirebaseHandle?
  
  var tasksDeletedCircleQueryHandle: FirebaseHandle?
  var usersCircleQueryHandle: FirebaseHandle?
  
  
  var usersDeletedCircleQueryHandle: FirebaseHandle?
  var usersMovedCircleQueryHandle: FirebaseHandle?
  var usersExitCircleQueryHandle: FirebaseHandle?
  var usersEnterCircleQueryHandle: FirebaseHandle?
  
  // create location manager variable
  var locationManager:CLLocationManager!
  
  //Notification center
  private var notification: NSObjectProtocol?
  
  // tasks array for nearby tasks
  var tasks = [Task?]()
  
  // geofire
  var tasksLocationsRef:FIRDatabaseReference?
  var usersLocationsRef:FIRDatabaseReference?
  var tasksGeoFire: GeoFire?
  var usersGeoFire: GeoFire?
  
  // task self destruct timer
  var expirationTimer: Timer? = nil
  var locationUpdateTimer: Timer? = nil
  var fakeUsersTimer: Timer? = nil
  var fakeUsersCreated = false
  //Checks
  var isLocationNotAuthorised = false
  var isLoadingFirebase = false
  // Cluster
  let clusterManager = ClusterManager()
  //
  var mTaskDescription : String?
  // expired task point
  var expiredAnnotation =  CustomExpireTask()
  
  //indicator
  @IBOutlet weak var indicatorView : UIActivityIndicatorView!
  var mTaskScore = 0
  
  deinit {
    // get rid of observers when denit
  }
  
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    //Check for location when user come foreground
    observeUserLocationAuth()
    
    if isLoadingFirebase {
      startLoderAnimation()
    }
    // center map to user's location when map appears
    if let userCoordinate = locationManager.location?.coordinate {
      self.mapView.setCenter(userCoordinate, animated: true)
    }
    //start updationg users icons
    startUpdationForUserLocation()
    
    //Check Fake tasks are available
    //  if checkFakeTakViewed() != true {
    let defaults = UserDefaults.standard
    let boolForTask2 = defaults.bool(forKey: Constants.ONBOARDING_TASK2_VIEWED_KEY)
    // Remove chat task if completed
    if boolForTask2 == true {
      for (index, element) in tasks.enumerated() {
        if element?.taskDescription == ONBOARDING_TASK_2_DESCRIPTION {
          UpdatePointsServer(1, (FIRAuth.auth()?.currentUser?.uid)!)
          mTaskScore = mTaskScore + 1
          self.usersRef?.child((FIRAuth.auth()?.currentUser?.uid)!).child("score").setValue(mTaskScore)
          removeOnboardingFakeTask(carousel: carouselView, cardIndex: index, userId: (element?.taskID)!)
          showUserThankedAnimation()
          self.pointsLabel.text = String(2)
          
        }
      }
    }
    
  }
  
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let viewHeight  = UIScreen.main.bounds.size.height <= 568 ? 232 : 264
    mCarouselHeight.constant = CGFloat(viewHeight)
    
    clusterManager.cellSize = nil
    clusterManager.maxZoomLevel = 12
    clusterManager.minCountForClustering = 4
    clusterManager.clusterPosition = .average
    clusterManager.shouldRemoveInvisibleAnnotations = false
    
    
    // check notification id
    if let refreshedToken = FIRInstanceID.instanceID().token() {
      print("InstanceID token: \(refreshedToken)")
    }
    
    //Check internet Connection
    let networkStatus = Reachbility.sharedInstance
    networkStatus.startNetworkReachabilityObserver()
    
    // set current user id
    currentUserId = FIRAuth.auth()?.currentUser?.uid
    
    // reset users to thank dictionary
    self.usersToThank = [:]
    
    
    
    // show user's position
    mapView.showsUserLocation = true
    // turn off compass on mapview
    mapView.showsCompass = false
    
    
    
    // setup mapview delegate
    mapView.delegate = self
    
    // setup firebase/geofire
    ref = FIRDatabase.database().reference()
    tasksRef = ref?.child("tasks")
    channelsRef = ref?.child("channels")
    usersRef = ref?.child("users")
    tasksLocationsRef = ref?.child("tasks_locations")
    usersLocationsRef = ref?.child("users_locations")
    taskViewRef = ref?.child("task_views")
    tasksGeoFire = GeoFire(firebaseRef: tasksLocationsRef)
    usersGeoFire = GeoFire(firebaseRef: usersLocationsRef)
    
    //get user Location
    locationManager = CLLocationManager()
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.distanceFilter = 20
    locationManager .stopMonitoringSignificantLocationChanges()
    locationManager.pausesLocationUpdatesAutomatically = false
    // allows location manager to update location in the background
    locationManager.allowsBackgroundLocationUpdates = true
    locationManager.startUpdatingLocation()
    
    
    // set region that is shown on the map
    setupLocationRegion()
    
    // get updated user location coordinates
    getCurrentUserLocation()
    
    // setup carousel view
    carouselView.type = iCarouselType.linear
    carouselView.isPagingEnabled = true
    carouselView.bounces = true
    carouselView.bounceDistance = 0.2
    carouselView.scrollSpeed = 1.0
    
    // add gesture swipe to carousel
    // check if current card is a onboarding task by check the description by adding gesture recognizer
    
    // swipe left recognizer
    let swipeLeftRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(self.onboardingTaskSwiped(_:)))
    swipeLeftRecognizer.direction = .left
    swipeLeftRecognizer.delegate = self
    
    // swipe right recognizer
    let swipeRightRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(self.onboardingTaskSwiped(_:)))
    swipeRightRecognizer.direction = .right
    swipeRightRecognizer.delegate = self
    
    // add recognizers to the carousel view
    carouselView.addGestureRecognizer(swipeLeftRecognizer)
    carouselView.addGestureRecognizer(swipeRightRecognizer)
    
    // create points uiview
    let pointsShadowGradientView = createPointsView()
    self.view.addSubview(pointsShadowGradientView)
    if checkFakeTakViewed() == true {
      getPreviousTask()
      initUserAuth()
      self.newItemSwiped = true
    }
    else {
      canCreateNewtask = true
      self.newItemSwiped = false
      isLoadingFirebase = false
      createFakeTasks()
      initUserAuth()
    }
    
  }
  
  func checkFakeTakViewed() -> Bool {
    let defaults = UserDefaults.standard
    let boolForTask1 = defaults.bool(forKey: Constants.ONBOARDING_TASK1_VIEWED_KEY)
    let boolForTask2 = defaults.bool(forKey: Constants.ONBOARDING_TASK2_VIEWED_KEY)
    let boolForTask3 = defaults.bool(forKey: Constants.ONBOARDING_TASK3_VIEWED_KEY)
    if boolForTask1 != true || boolForTask2 != true || boolForTask3 != true {
      return false
    }
    return true
    
  }
  
  func getFakeTasksCount() -> Int {
    var count = 1
    let defaults = UserDefaults.standard
    let boolForTask1 = defaults.bool(forKey: Constants.ONBOARDING_TASK1_VIEWED_KEY)
    let boolForTask2 = defaults.bool(forKey: Constants.ONBOARDING_TASK2_VIEWED_KEY)
    let boolForTask3 = defaults.bool(forKey: Constants.ONBOARDING_TASK3_VIEWED_KEY)
    if boolForTask3 == false && boolForTask1 == true && boolForTask2 == true || (newItemSwiped == true || currentUserTaskSaved == true){
      count = 1
    }
    if boolForTask1 != true  {
      count += 1
    }
    if boolForTask2 != true  {
      count += 1
    }
    if boolForTask3 != true  {
      count += 1
    }
    return count
    
  }
  
  func initUserAuth() {
    
    if (currentUserId == nil) { return }
    
    // create task for current user
    // and also set channel for chat for current user's chat
    if (tasks.count == 0 || checkFakeTakViewed() == false) {
      print("current user task created")
      
      if (self.userLatitude != nil && self.userLongitude != nil) {
        // TODO fix
        let timeStamp = Int(NSDate.timeIntervalSinceReferenceDate*1000)
        tasks.insert(Task(userId: currentUserId!, taskDescription: "loading", latitude: self.userLatitude!, longitude: self.userLongitude!, completed: false, timeCreated: Date(), timeUpdated: Date(), taskID: "\(timeStamp)", recentActivity: false, userMovedOutside: false), at: 0)
        carouselView.reloadData()
      }
      self.currentUserTaskSaved = false
      
    }
    if checkFakeTakViewed() == false && self.tasks.count > 0 {
      self.carouselView.scrollToItem(at: 1, animated: true)
    }
    // if no chat channels
    // append current user's channel
    if(tasks.count > 0){
      print("current user chat channel appended")
      // TODO fix
      let task = tasks.last as? Task;
      chatChannels.append((task?.taskID!)!)
    }
    
    // query for tasks nearby
    if let userLatitude = self.userLatitude, let userLongitude = self.userLongitude {
      queryTasksAroundCurrentLocation(latitude: userLatitude, longitude: userLongitude)
      
      // query for users nearby
      queryUsersAroundCurrentLocation(latitude: userLatitude, longitude: userLongitude)
    }
    
    // observe for points
    observeForCurrentUserPoints()
    
    // add current user's location to geofire
    self.addCurrentUserLocationToFirebase()
  }
  
  func addCurrentUserLocationToFirebase() {
    // add current user's location to firebase/geofire
    
    self.getCurrentUserLocation()
    if self.locationManager.location != nil {
      self.usersGeoFire?.setLocation( self.locationManager.location, forKey: "\(String(describing: FIRAuth.auth()?.currentUser?.uid))")
      
    }
    
    //Updated Time
    let dateformatter = DateStringFormatterHelper()
    let stringDate = dateformatter.convertDateToString(date: NSDate() as Date)
    usersRef?.child((FIRAuth.auth()?.currentUser?.uid)!).child("UpdatedAt").setValue(stringDate)
    
  }
  
  func showUserThankedAnimation() {
    
    if playingThanksAnim == true { return }
    let viewFrame = self.view.frame
    thanksAnimImageView = UIImageView(frame: CGRect(x: viewFrame.origin.x, y: viewFrame.origin.y, width: viewFrame.size.width, height: viewFrame.size.height))
    flareAnimImageView = UIImageView(frame: CGRect(x: viewFrame.origin.x, y: viewFrame.origin.y, width: viewFrame.size.width, height: viewFrame.size.height))
    flareAnimImageView.image = #imageLiteral(resourceName: "flareImage");
    flareAnimImageView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
    
    thanksAnimImageView.contentMode = .scaleAspectFit
    flareAnimImageView.contentMode = .scaleAspectFill
    
    let imageListArray: NSMutableArray = []
    for countValue in 1...51
    {
      let imageName : String = "fux00\(countValue).png"
      let image  = UIImage(named:imageName)
      imageListArray.add(image!)
    }
    flareAnimation(view: flareAnimImageView, duration: Constants.THANKS_ANIMATION_DURATION)
    thanksAnimImageView.animationImages = imageListArray as? [UIImage]
    thanksAnimImageView.animationDuration = Constants.THANKS_ANIMATION_DURATION
    self.view.addSubview(flareAnimImageView)
    self.view.addSubview(thanksAnimImageView)
    
    playingThanksAnim = true
    thanksAnimImageView.startAnimating()
    self.perform(#selector(MainViewController.afterThanksAnimation), with: nil, afterDelay: thanksAnimImageView.animationDuration-0.5)
  }
  
  //Start Flare Animation for thanks
  func flareAnimation(view: UIView, duration: Double = 1) {
    if view.layer.animation(forKey: kRotationAnimationKey) == nil {
      let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
      rotationAnimation.fromValue = 0.0
      rotationAnimation.toValue = Float(.pi * 2.0)
      rotationAnimation.duration = duration
      rotationAnimation.repeatCount = Float.infinity
      view.layer.add(rotationAnimation, forKey: kRotationAnimationKey)
    }
  }
  
  //Stop flare Animation
  func stopFlareAnimation(view: UIView) {
    if view.layer.animation(forKey: kRotationAnimationKey) != nil {
      view.layer.removeAnimation(forKey: kRotationAnimationKey)
    }
  }
  
  func afterThanksAnimation() {
    stopFlareAnimation(view: flareAnimImageView)
    flareAnimImageView.removeFromSuperview()
    thanksAnimImageView.stopAnimating()
    thanksAnimImageView.removeFromSuperview()
    playingThanksAnim = false
  }
  
  func observeForCurrentUserPoints() {
    // create observer for current user's points
    let currentUserId = FIRAuth.auth()?.currentUser?.uid
    self.currentUserHandle = self.usersRef?.child(currentUserId!).observe(.value, with: { (snapshot) in
      
      let value = snapshot.value as? NSDictionary
      let userPoints = value?["score"] as? Int ?? 0
      
      print("current user just got points \(userPoints)")
      
      // update the points label if they get a point
      self.pointsLabel.text = String(userPoints)
    })
  }
  
  func checkIfNoPoints() {
    // TODO if the current user has no points
    // make the points gradient view invisible
    
    // if the user has points make the points gradient view visible
  }
  
  // create points view
  func createPointsView() -> UIView{
    
    // create shadow view to superview diagonal gradient
    let shadowView = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
    shadowView.backgroundColor = UIColor.clear
    shadowView.center.x = self.view.bounds.maxX - 50
    shadowView.center.y = 73
    shadowView.layer.shadowColor = UIColor.black.cgColor
    shadowView.layer.shadowOffset = CGSize(width: 0, height: 10)
    shadowView.layer.shadowOpacity = 0.3
    shadowView.layer.shadowRadius = 15.0
    
    // create diagonal gradient to show points
    let pointsGradientView = DiagonalGradientView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
    pointsGradientView.layer.cornerRadius = pointsGradientView.bounds.width/2
    //pointsGradientView.center.x = self.view.bounds.maxX - 50
    //pointsGradientView.center.y = 73
    pointsGradientView.layer.masksToBounds = true
    pointsGradientView.tag = POINTS_GRADIENT_VIEW_TAG
    
    // create points count label to hold the number of points the current user has
    pointsLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
    pointsLabel.text = "0"
    pointsLabel.font = UIFont.systemFont(ofSize: 24)
    pointsLabel.textColor = UIColor.white
    pointsLabel.textAlignment = .center
    pointsLabel.center.x = pointsGradientView.frame.size.width/2
    pointsLabel.tag = POINTS_GRADIENT_VIEW_LABEL_TAG
    
    pointsGradientView.addSubview(pointsLabel)
    shadowView.addSubview(pointsGradientView)
    
    // add gesture to show points profile view when tapped
    let pointsTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.showPointsProfileView(_:)))
    shadowView.addGestureRecognizer(pointsTapGesture)
    
    return shadowView
  }
  
  func showPointsProfileView(_:UIGestureRecognizer) {
    // center the map on current user's location
    //setupLocationRegion()
    mapView.setUserTrackingMode(.follow, animated: true)
    // show points pofile view
    let pointsProfileView = UIView(frame: CGRect(x: 0, y: 0, width: mapView.frame.size.width, height: self.view.bounds.height))
    pointsProfileView.center = self.view.center
    pointsProfileView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
    pointsProfileView.tag = self.POINTS_PROFILE_VIEW_TAG
    
    // create horizontal gradient card for showing points
    let horizontalGradientView = HorizontalGradientView(frame: CGRect(x: 0, y: 0, width: pointsProfileView.frame.size.width-30, height: 170))
    horizontalGradientView.center.y = pointsProfileView.bounds.height/4
    horizontalGradientView.center.x = pointsProfileView.center.x
    horizontalGradientView.layer.cornerRadius = 4
    horizontalGradientView.clipsToBounds = true
    
    
    // create label for text
    let textLabel = UILabel(frame: CGRect(x: 0, y: 0, width: horizontalGradientView.frame.size.width-60, height: 50))
    textLabel.text = "Your mayo points can be exchanged for  rewards in the future so hang on to it!"
    textLabel.textAlignment = .left
    textLabel.font = UIFont.systemFont(ofSize: 14)
    textLabel.lineBreakMode = .byWordWrapping
    textLabel.numberOfLines = 2
    textLabel.adjustsFontSizeToFitWidth = true
    textLabel.center.x = horizontalGradientView.bounds.width/2 - 10
    textLabel.center.y = 30
    textLabel.textColor = UIColor.white
    
    // create label for 'You have'
    let youHaveLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
    youHaveLabel.font = UIFont.systemFont(ofSize: 24)
    youHaveLabel.textColor = UIColor.white
    youHaveLabel.textAlignment = .center
    youHaveLabel.text = "You have"
    youHaveLabel.center.x = pointsProfileView.bounds.width/2 - 20
    youHaveLabel.center.y = textLabel.bounds.maxY + 30
    
    let closeGesture = UITapGestureRecognizer(target: self, action: #selector(self.removePointsProfile(_:)))
    //closeButton.addGestureRecognizer(closeGesture)
    
    // create label for score
    let scoreLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 150, height: 40))
    scoreLabel.font = UIFont.systemFont(ofSize: 24)
    scoreLabel.textColor = UIColor.white
    scoreLabel.textAlignment = .center
    // get the score from points label and set it
    let pointsGradientViewLabel = self.view.viewWithTag(POINTS_GRADIENT_VIEW_LABEL_TAG) as? UILabel
    scoreLabel.text = "\((pointsGradientViewLabel?.text)!)"
    scoreLabel.center.x = horizontalGradientView.bounds.width/2
    scoreLabel.center.y = youHaveLabel.center.y + 50
    
    // create close button
    let closeButton = UIButton(frame: CGRect(x: 0, y: 0, width: 12, height: 12))
    let closeImage = UIImage(named: "close")
    closeButton.setImage(closeImage, for: .normal)
    closeButton.center.x = horizontalGradientView.bounds.maxX - 20
    closeButton.center.y = 25
    closeButton.addTarget(self, action: #selector(self.removePointsProfile(_:)), for: UIControlEvents.touchUpInside)
    
    // add to superview
    horizontalGradientView.addSubview(textLabel)
    horizontalGradientView.addSubview(youHaveLabel)
    horizontalGradientView.addSubview(scoreLabel)
    horizontalGradientView.addSubview(closeButton)
    horizontalGradientView.addGestureRecognizer(closeGesture)
    pointsProfileView.addSubview(horizontalGradientView)
    
    self.view.addSubview(pointsProfileView)
  }
  
  // remove points profile view
  func removePointsProfile(_:UITapGestureRecognizer) {
    let pointsProfileView = self.view.viewWithTag(self.POINTS_PROFILE_VIEW_TAG)
    pointsProfileView?.removeFromSuperview()
  }
  
  // creates 3 fake tasks to show on load
  func createFakeTasks() {
    
    // update user location
    self.getCurrentUserLocation()
    let cardColor = CardColor()
    // get standard defaults to check if the current user has done the onboarding tasks
    let defaults = UserDefaults.standard
    
    // get the first bool for the onboarding task
    let boolForTask1 = defaults.bool(forKey: Constants.ONBOARDING_TASK1_VIEWED_KEY)
    
    // only show the first onboarding task if it hasn't been shown before
    if boolForTask1 != true {
      let timeStamp = Int(NSDate.timeIntervalSinceReferenceDate*1000)
      let task1 = Task(userId: "fakeuserid1", taskDescription: self.ONBOARDING_TASK_1_DESCRIPTION, latitude: self.userLatitude! + 0.0003, longitude: self.userLongitude! + 0.0003, completed: false, taskID: "\(101)", recentActivity: false, userMovedOutside: false)
      let randomColorGradient = cardColor.generateRandomColor()
      // save the colors to the task
      task1.setGradientColors(startColor: randomColorGradient[0], endColor: randomColorGradient[1])
      self.tasks.append(task1)
      addMapPin(task: task1, carouselIndex: self.tasks.count-1)
    }
    
    
    // get the second bool for the onboarding task
    let boolForTask2 = defaults.bool(forKey: Constants.ONBOARDING_TASK2_VIEWED_KEY)
    
    // only show if the second onboarding task if it hasn't been shown before
    if boolForTask2 != true {
      let timeStamp = Int(NSDate.timeIntervalSinceReferenceDate*1000)
      let task2 = Task(userId: "fakeuserid2", taskDescription: self.ONBOARDING_TASK_2_DESCRIPTION, latitude: self.userLatitude! + 0.0001, longitude: self.userLongitude! + 0.0001, completed: false, taskID: "\(102)", recentActivity: false, userMovedOutside: false)
      let randomColorGradient = cardColor.generateRandomColor()
      
      // save the colors to the task
      task2.setGradientColors(startColor: randomColorGradient[0], endColor: randomColorGradient[1])
      self.tasks.append(task2)
      addMapPin(task: task2, carouselIndex: self.tasks.count-1)
    }
    
    // get the third bool for the onboarding task
    let boolForTask3 = defaults.bool(forKey: Constants.ONBOARDING_TASK3_VIEWED_KEY)
    
    // only show if the third onboarding task if it hasn't been shown before
    if boolForTask3 != true {
      let timeStamp = Int(NSDate.timeIntervalSinceReferenceDate*1000)
      let task3 = Task(userId: "fakeuserid3", taskDescription: self.ONBOARDING_TASK_3_DESCRIPTION, latitude: self.userLatitude! + 0.0003, longitude: self.userLongitude! - 0.0003, completed: false, taskID: "\(103)", recentActivity: false, userMovedOutside: false)
      let randomColorGradient = cardColor.generateRandomColor()
      
      // save the colors to the task
      task3.setGradientColors(startColor: randomColorGradient[0], endColor: randomColorGradient[1])
      self.tasks.append(task3)
      addMapPin(task: task3, carouselIndex: self.tasks.count-1)
    }
    carouselView.reloadData()
  }
  
  // creates fake users nearby
  func createFakeUsers() {
    
    // get a random number from 2 to 5 for number of users
    let randomNumberOfUsers = generateRandomNumber(endingNumber: 4) + 2
    
    for _ in 1...randomNumberOfUsers {
      // call create fake users
      createFakeUser()
    }
  }
  
  // create fake user
  func createFakeUser() {
    
    // update current user's location
    self.getCurrentUserLocation()
    
    // generate random lat offet
    let randomLatOffset = generateRandomDegreesOffset()
    
    // generate random long offset
    let randomLongOffset = generateRandomDegreesOffset()
    
    // create new location coordinate
    let newLoc = CLLocationCoordinate2D(latitude: self.userLatitude! + randomLatOffset, longitude: self.userLongitude! + randomLongOffset)
    
    //Add Exipre Time for users
    let calendar = Calendar.current
    let minutesAgo = generateRandomNumber(endingNumber: 7)
    let date = calendar.date(byAdding: .minute, value: -minutesAgo, to: Date())
    
    // annotation for user markers
    self.addUserPin(latitude: newLoc.latitude, longitude: newLoc.longitude, userId: Constants.FAKE_USER_ID, updatedTime:date! )
    
  }
  
  // creates random degrees offset from .0001 to .001
  func generateRandomDegreesOffset() -> Double {
    let offset = Double(1 + generateRandomNumber(endingNumber: 10)) * 0.0001
    
    // create random number either 0 or 1
    let sign = generateRandomNumber(endingNumber: 2)
    
    // if sign is 0, return positive
    if sign == 0 {
      return offset
    } else {
      // else, if sign is 1 return negative
      return -offset
    }
  }
  
  // generate random weight interval
  func generateWeightedTimeInterval() -> Int {
    // 20% 1 min
    // 20% 2-3 min
    // 60% 4-6 min
    let weights = [1,1,1,1,2,2,3,3,4,4,4,4,5,5,5,5,6,6,6,6]
    let randomIndex = generateRandomNumber(endingNumber: 20)
    let selectedWeight = weights[randomIndex]
    
    // generate random number/seconds for time interval from 1 to 60
    let randomSeconds = 1 + generateRandomNumber(endingNumber: 60)
    
    // get the random time interval with weight and seconds
    let randomTime = randomSeconds * selectedWeight
    
    return randomTime
  }
  
  // generate random number from 0 to endingNumber
  func generateRandomNumber(endingNumber:Int) -> Int {
    
    // creates random number between 0 and endingNumber
    // not including randomNumber
    let randomNum:UInt32 = arc4random_uniform(UInt32(endingNumber))
    return Int(randomNum)
  }
  
  
  func deleteFakeUser(_ annotation: MKAnnotation) {
    
    // removes annotation from mapview a user
    self.mapView.removeAnnotation(annotation)
    
  }
  
  // setup pins for nearby tasks
  func addMapPin(task: Task, carouselIndex: Int) {
    // add pin for task
    //let annotation = MKPointAnnotation()
    if carouselIndex == 0 {
      let annotation = CustomFocusTaskMapAnnotation(currentCarouselIndex: carouselIndex, taskUserId: task.taskID!)
      annotation.coordinate = CLLocationCoordinate2D(latitude: (task.latitude), longitude: (task.longitude))
      annotation.style = .color(#colorLiteral(red: 0, green: 0.5901804566, blue: 0.758269012, alpha: 1), radius: 30)
                  self.mapView.addAnnotation(annotation)
//      clusterManager.add(annotation)
      
    }
    else {
      let annotation = CustomTaskMapAnnotation(currentCarouselIndex: carouselIndex, taskUserId: task.taskID!)
      annotation.coordinate = CLLocationCoordinate2D(latitude: (task.latitude), longitude: (task.longitude))
      annotation.style = .color(#colorLiteral(red: 0, green: 0.5901804566, blue: 0.758269012, alpha: 1), radius: 30) //.image(#imageLiteral(resourceName: "newNotificaitonIcon"))
      //            self.mapView.addAnnotation(annotation)
      clusterManager.add(annotation)
    }
    
    clusterManager.reload(mapView, visibleMapRect: mapView.visibleMapRect)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    // hides navigation bar for home viewcontroller
    self.navigationController?.isNavigationBarHidden = true
    checkNotificationPermission()
    
  }
  override func viewWillDisappear(_ animated: Bool) {
    // show navigation bar on chat view controller
    self.navigationController?.isNavigationBarHidden = false
    locationUpdateTimer?.invalidate()
    locationUpdateTimer = nil
    
    if let notification = notification {
      NotificationCenter.default.removeObserver(notification)
    }
    
  }
  
  // query users nearby
  func queryUsersAroundCurrentLocation(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
    fakeUsersCreated = false
    // Query locations at latitude, longitutde with a radius of queryDistance
    // 200 meters = .2 for geofire units
    let center = CLLocation(latitude: latitude, longitude: longitude)
    usersCircleQuery = usersGeoFire?.query(at: center, withRadius: queryDistance/1000)
    
    usersEnterCircleQueryHandle = usersCircleQuery?.observe(.keyEntered, with: { (key: String?, location: CLLocation?) in
      print("Key '\(key!)' entered the search are and is at location '\(location!)'")
      
      let key1 = key?.replacingOccurrences(of: "Optional(\"", with: "")
      let userId = key1?.replacingOccurrences(of: "\")", with: "")
      
      self.usersRef?.child(userId!).child("UpdatedAt").observeSingleEvent(of: .value, with: { (snapshot) in
        if let lastUpdateTime = snapshot.value as? String {
          let currentDate = Date()
          let dateformatter = DateStringFormatterHelper()
          let userLastUpdate = dateformatter.convertStringToDate(datestring: lastUpdateTime)
          //check user active from 3 days
          if currentDate.seconds(from: userLastUpdate ) < self.SECONDS_IN_DAY * 3 {
            if !self.nearbyUsers.contains(key!) && key! != FIRAuth.auth()!.currentUser!.uid {
              //Create marker for user
              if self.nearbyUsers.contains(userId!) == false {
                self.nearbyUsers.append(userId!)
                self.addUserPin(latitude: (location?.coordinate.latitude)!, longitude: (location?.coordinate.longitude)!, userId: userId!, updatedTime:userLastUpdate )
              }
            }
          }
        }
        
      })
      
      let when = DispatchTime.now() + 6 // change 6 to desired number of seconds
      DispatchQueue.main.asyncAfter(deadline: when) {
        if self.nearbyUsers.count <= 6  && self.fakeUsersCreated == false {
          self.fakeUsersCreated = true
          self.createFakeUsers()
        }
      }
      
      
    })
    
    // remove users circle when it leaves
    usersExitCircleQueryHandle = usersCircleQuery?.observe(.keyExited, with: { (key: String!, location: CLLocation!) in
      print("user \(key) left the area")
      // Remove observer
      print("user observer removed")
      let key1 = key?.replacingOccurrences(of: "Optional(\"", with: "")
      let userId = key1?.replacingOccurrences(of: "\")", with: "")
      
      if userId == self.currentUserId {
        self.updateNearBytask()
      }
      
      // remove user in the nearby userlist.
      var index = 0
      for userKey in self.nearbyUsers {
        if userKey == userId {
          self.nearbyUsers.remove(at: index)
          break
        }
        
        index = index + 1
      }
      
      // loop through the user annotations and remove it
      for annotation in self.mapView.annotations {
        if annotation is CustomUserMapAnnotation {
          let customUserAnnotation = annotation as! CustomUserMapAnnotation
          if customUserAnnotation.userId == userId {
            let viewAnnotation = self.mapView.view(for: annotation)
            UIView.animate(withDuration: 2, animations: {
              viewAnnotation?.alpha = 0
            }, completion: { (complete) in
              self.mapView.removeAnnotation(customUserAnnotation)
            })
            
          }
        }
      }
      
      
    })
    
    // update user location when it moves
    usersMovedCircleQueryHandle = usersCircleQuery?.observe(.keyMoved, with: { (key: String!, location: CLLocation!) in
      print("user \(key) moved ")
      let key1 = key?.replacingOccurrences(of: "Optional(\"", with: "")
      let userId = key1?.replacingOccurrences(of: "\")", with: "")
      
      // loop through the user annotations and remove it
      for annotation in self.mapView.annotations {
        if annotation is CustomUserMapAnnotation {
          let customUserAnnotation = annotation as! CustomUserMapAnnotation
          //view for annotation
          let viewAnnotation = self.mapView.view(for: annotation)
          if customUserAnnotation.userId == userId {
            viewAnnotation?.image = #imageLiteral(resourceName: "greenDot")
            
            customUserAnnotation.lastUpdatedTime = Date()
            UIView.animate(withDuration: 1, animations: {
              customUserAnnotation.coordinate = location.coordinate
              viewAnnotation?.alpha = 1
            })
          }
        }
      }
      if !self.nearbyUsers.contains(userId!)  && userId != FIRAuth.auth()!.currentUser!.uid  {
        self.nearbyUsers.append(userId!)
        self.addUserPin(latitude: (location?.coordinate.latitude)!, longitude: (location?.coordinate.longitude)!, userId: userId!, updatedTime: Date() )
      }
      
    })
    
  }
  
  // get tasks around current location
  func queryTasksAroundCurrentLocation(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
    self.indicatorView.isHidden = false
    let when = DispatchTime.now() + 8
    DispatchQueue.main.asyncAfter(deadline: when){
      // When No Task available
      self.removeFirebaseLoader()
    }
    
    let center = CLLocation(latitude: latitude, longitude: longitude)
    
    
    // Query locations at latitude, longitutde with a radius of queryDistance
    // 200 meters = .2 for geofire units
    tasksCircleQuery = tasksGeoFire?.query(at: center, withRadius: queryDistance/1000)
    
    //        self.removeCircle()
    //        self.addRadiusCircle(location: center)
    tasksDeletedCircleQueryHandle = tasksCircleQuery?.observe(.keyExited, with: { (key: String!, location: CLLocation!) in
      
      // when a new task is deleted
      print("a new key was deleted")
      
      // remove task with that id and get its index
      for (index, task) in self.tasks.enumerated() {
        
        // if the task's id matches the key that was deleted
        // and also check that the task is not equal to current user
        if task?.userId == key && key != FIRAuth.auth()?.currentUser?.uid {
          
          // remove the task from the tasks array
          self.tasks.remove(at: index)
          
          // remove that card based on its key
          UIView.animate(withDuration: 1, animations: {
            self.carouselView.removeItem(at: index, animated: true)
          })
          
          // remove the pin for that card from the map
          for annotation in self.mapView.annotations {
            
            // check if its a task map annotation or focused task map annotaiton
            if annotation is CustomTaskMapAnnotation {
              
              let customAnnotation = annotation as! CustomTaskMapAnnotation
              
              // check if the index matches the index of the annotation
              if customAnnotation.currentCarouselIndex == index {
                // if it matches remove the annotaiton
                self.mapView.removeAnnotation(customAnnotation)
                
                //and change the index for all the icons that are greater than it
                self.updatePinsAfterDeletion(deletedIndex: index)
                
              }
              
            }
            
            if annotation is CustomFocusTaskMapAnnotation {
              let customFocusAnnotation = annotation as! CustomFocusTaskMapAnnotation
              
              // if the index of of annotation is equal to deleted index
              if customFocusAnnotation.currentCarouselIndex == index {
                // remove this annotation
                self.mapView.removeAnnotation(customFocusAnnotation)
                
                //and change the index for all the icons that are greater than it
                self.updatePinsAfterDeletion(deletedIndex: index)
                
              }
            }
            
            // update annotation indexes
            self.updateMapAnnotationCardIndexes()
            
          }
          
        }
        
      }
      
    })
    
    // listen for changes for when new tasks are created
    tasksCircleQueryHandle = tasksCircleQuery?.observe(.keyEntered, with: { (key: String!, location: CLLocation!) in
      print("Key '\(key)' entered the search area and is at location '\(location)'")
      
      //Remove loader
      self.removeFirebaseLoader()
      
      let taskRef = self.tasksRef?.child(key)
      self.tasksRefHandle = taskRef?.observe(FIRDataEventType.value, with: { (snapshot) in
        
        let taskDict = snapshot.value as? [String : AnyObject] ?? [:]
        print("key: \(key) task dictionary: \(taskDict)")
        
        let dateformatter = DateStringFormatterHelper()
        // Check - don't add tasks that are older than 1 hour
        if !taskDict.isEmpty && taskDict["completed"] as! Bool == false {
          
          // get the time created for the current task
          let taskTimeCreated = dateformatter.convertStringToDate(datestring: taskDict["timeUpdated"] as! String)
          
          // get current time
          let currentTime = Date()
          
          // get the difference between time created and current time
          let timeDifference = currentTime.seconds(from: taskTimeCreated)
          print("time difference for task: \(timeDifference)")
          
          // if time difference is greater than 1 hour (3600 seconds)
          // return and don't add this task to tasks
          if timeDifference > self.SECONDS_IN_HOUR {
            return
          }
        }
        
        // only process taskDict if not completed
        // and not equal to own uid
        // Remove Complete from here
        //Lakshmi
        //                && (taskDict["createdby"] as? String  != FIRAuth.auth()?.currentUser?.uid)
        if !taskDict.isEmpty {
          //
          // send the current user local notification
          // that there is a new task
          
          // Check - don't add duplicates
          
          // check task exists
          for task in self.tasks {
            // the task is already present in the tasks
            //task?.taskID == taskDict["createdby"] as? String ||
            if  task?.taskID == taskDict["taskID"] as? String {
              //for creator of Task or already existing Task
              if taskDict["completed"] as! Bool == true {
                for (index, task) in self.tasks.enumerated() {
                  if task?.taskID == taskDict["taskID"] as? String && task?.completed == false {
                    self.tasks[index]?.completed = true
                    self.tasks.append(self.tasks[index])
                    self.tasks.remove(at: index)
                    self.removeCarousel(index)
                    self.removeAnnotationForTask((task?.taskID)!)
                    
                    
                    if self.tasks.count <= 1 {
                      self.newItemSwiped = true
                      self.carouselView.reloadData()
                    }
                  }
                }
              }
              // update annotation indexes
              self.updateMapAnnotationCardIndexes()
              // return so no duplicates are added
              return
            }
            
          }
          
          //Send Task notification
          self.sendNewTaskNotification()
          
          // adds key for task to chat channels array
          self.chatChannels.append(taskDict["taskID"] as! String)
          
          let taskCompleted = taskDict["completed"] as! Bool
          let taskTimeCreated = dateformatter.convertStringToDate(datestring: taskDict["timeCreated"] as! String)
          let taskTimeUpdated = dateformatter.convertStringToDate(datestring: taskDict["timeUpdated"] as! String)
          let taskDescription = taskDict["taskDescription"] as! String
          
          let timeStamp = taskDict["taskID"] as! String
          var recentActivity = false
          if let activity = taskDict["recentActivity"] as? Bool {
            recentActivity = activity
          }
          var userMovedOutside = false
          if let movedOuside = taskDict["userMovedOutside"] as? Bool {
            userMovedOutside = movedOuside
          }
          
          var taskStartColor: String? = nil
          var taskEndColor: String? = nil
          //
          
          
          let newTask = Task(userId: key, taskDescription: taskDescription, latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, completed: taskCompleted, timeCreated: taskTimeCreated, timeUpdated: taskTimeUpdated, taskID: "\(timeStamp)",recentActivity: recentActivity, userMovedOutside: userMovedOutside)
          
          
          // check if the task already has start and end colors saved
          if taskDict["startColor"] != nil,  taskDict["endColor"] != nil
          {
            // if they have start color and end color
            taskStartColor = taskDict["startColor"] as? String
            taskEndColor = taskDict["endColor"] as? String
            
            newTask.setGradientColors(startColor: taskStartColor, endColor: taskEndColor)
          } else {
            // if they have nil for start and end colors
            newTask.setGradientColors(startColor: nil, endColor: nil)
          }
          if newTask.userMovedOutside == true && newTask.completed == false {
            self.checkTaskParticipation(newTask, callBack: { (isParticipated) in
              if isParticipated {
                self.appendNewTask(newTask)
              }
            })
          } else {
            self.appendNewTask(newTask)
          }
          
        }
        else if  !taskDict.isEmpty && taskDict["completed"] as! Bool == true {
          for (index, task) in self.tasks.enumerated() {
            if task?.taskID == taskDict["taskID"] as? String {
              self.removeCarousel(index)
              self.tasks.remove(at: index);
              self.removeAnnotationForTask((task?.taskID)!)
              self.updateMapAnnotationCardIndexes()
              
              if self.tasks.count == 0 {
                UserDefaults.standard.set(nil, forKey: Constants.PENDING_TASKS)
                if (self.tasks.count == 0) {
                  print("current user task created")
                  
                  if (self.userLatitude != nil && self.userLongitude != nil) {
                    // TODO fix
                    let timeStamp = Int(NSDate.timeIntervalSinceReferenceDate*1000)
                    self.tasks.append(
                      Task(userId: self.currentUserId!, taskDescription: "", latitude: self.userLatitude!, longitude: self.userLongitude!, completed: false, timeCreated: Date(), timeUpdated: Date(), taskID: "\(timeStamp)",recentActivity: false, userMovedOutside: false)
                    )
                    
                    self.carouselView.reloadData()
                    self.updateMapAnnotationCardIndexes()
                  }
                }
              }
              
            }
          }
        }
      })
      
    })
  }
  
  // send a local notification to user when a new task has been added
  func sendNewTaskNotification() {
    //        self.createLocalNotification(title: "New task nearby", body: "A new task was created nearby")
  }
  
  // after pin at the deleted index is removed, update the
  // pins and their carousel index
  func updatePinsAfterDeletion(deletedIndex: Int) {
    
    for annotation in self.mapView.annotations {
      
      // if annotation is customTaskMapAnnotation
      if annotation is CustomTaskMapAnnotation {
        let customAnnotation = annotation as! CustomTaskMapAnnotation
        if let carouselIndex = customAnnotation.currentCarouselIndex {
          if carouselIndex > deletedIndex {
            // if the annotation's carousel is greater than the deleted index decrease by 1
            customAnnotation.currentCarouselIndex = customAnnotation.currentCarouselIndex! - 1
          }
        }
        
      }
      
      // if annotation is customFocusTaskMapAnnotation
      if annotation is CustomFocusTaskMapAnnotation {
        let customFocusAnnotation = annotation as! CustomFocusTaskMapAnnotation
        if let carouselIndex = customFocusAnnotation.currentCarouselIndex {
          if carouselIndex > deletedIndex {
            // if the annotation's carousel is greater than the deleted index decrease by 1
            customFocusAnnotation.currentCarouselIndex = customFocusAnnotation.currentCarouselIndex! - 1
          }
        }
        
      }
      
    }
    
  }
  
  func addUserPin(latitude: CLLocationDegrees, longitude: CLLocationDegrees, userId: String, updatedTime: Date) {
    
    // check that the pin is not the same as current user
    if userId != FIRAuth.auth()?.currentUser?.uid {
      let userAnnotation = CustomUserMapAnnotation(userId: userId, date: updatedTime)
      userAnnotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
      self.mapView.addAnnotation(userAnnotation)
    }
  }
  
  // get current user's location
  func getCurrentUserLocation() {
    print("getcurrentUserLocation hit")
    // get user location coordinates
    if locationManager.location?.coordinate.latitude != nil && locationManager.location?.coordinate.longitude != nil {
      self.userLatitude = locationManager.location?.coordinate.latitude
      self.userLongitude = locationManager.location?.coordinate.longitude
    }
    else {
      let defaults = UserDefaults.standard
      guard let archived = defaults.object(forKey: Constants.LOCATION) as? Data,
        let location = NSKeyedUnarchiver.unarchiveObject(with: archived) as? CLLocation else {
          self.userLatitude = Constants.DEFAULT_LAT;
          self.userLongitude = Constants.DEFAULT_LNG;
          self.showLocationAlert()
          return
      }
      self.userLatitude = location.coordinate.latitude;
      self.userLongitude = location.coordinate.longitude;
      
    }
    if self.tasks.count > 0 {
      if let currentTask =  self.tasks[0] {
        if (self.userLatitude != nil && self.userLongitude != nil && currentTask.taskDescription == "") {
          currentTask.latitude = self.userLatitude!
          currentTask.longitude = self.userLongitude!
          self.tasks[0] = currentTask
        }
      }
    }
    print("current lat = \(String(describing: self.userLatitude))")
    print("current lng = \(String(describing: self.userLongitude))")
  }
  
  
  // sets up the desplay region
  func setupLocationRegion() {
    print("setupLocationRegionHit")
    // get current location
    getCurrentUserLocation()
    
    // setup zoom level for mapview
    let span = MKCoordinateSpanMake(0.0015, 0.0015)
    
    if userLatitude != nil && userLongitude != nil {
      let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: userLatitude!, longitude: userLongitude!), span: span)
      mapView.setRegion(region, animated: true)
      
      //setup mapview viewing angle
      let userCoordinate = CLLocationCoordinate2D(latitude: userLatitude!, longitude: userLongitude!)
      let mapCamera = MKMapCamera(lookingAtCenter: userCoordinate, fromDistance: CLLocationDistance(800), pitch: 45, heading: 0)
      mapView.setCamera(mapCamera, animated: true)
    }
  }
  
  
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    super.prepare(for: segue, sender: sender)
    
    if segue.identifier == "mainToChatVC" {
      
      let chatViewController = segue.destination as! ChatViewController
      
      //set sendername to empty string for now
      chatViewController.senderDisplayName = ""
      
      // get the current index of carousel view
      let channelIndex = self.carouselView.currentItemIndex
      
      // get colors from gradient view
      let shadowView = self.carouselView.currentItemView as! UIView
      let gradientView = shadowView.subviews[0] as! GradientView
      let startColor = gradientView.startColor
      let endColor = gradientView.endColor
      
      // use the index to fetch the id of the chat channel
      
      
      // pass the task description for the current task
      let currentTask = self.tasks[channelIndex] as! Task
      
      // setup display name and title of chat view controller
      chatViewController.title = currentTask.taskDescription
      chatViewController.isCompleted = currentTask.completed
      
      if currentTask.taskDescription == ONBOARDING_TASK_2_DESCRIPTION {
        chatViewController.isFakeTask = true
        chatViewController.isOwner = true
      }
      
      chatViewController.channelTopic = currentTask.taskDescription
      let chatChannelId = currentTask.taskID
      // pass chat channel id to the chat view controller
      chatViewController.channelId = chatChannelId
      if currentTask.userId == currentUserId {
        chatViewController.isOwner = true
      }
      // set channel and ref for chat view controller
      chatViewController.channelRef = channelsRef?.child(chatChannelId!)
      print("channel list; \(self.chatChannels)")
    }
  }
  
  //MARK:- Custom Methods
  
  
  @IBAction func actionMapStartFollow(_ sender: UIButton) {
    mapView.setUserTrackingMode(.follow, animated: true)
  }
  
  func appendNewTask(_ newTask: Task) {
    print("tasks: \(self.tasks)")
    print("tasks count: \(self.tasks.count)")
    
    if newTask.completed == true {
      self.tasks.append(newTask)
    } else {
      let carouselIndex = self.getFakeTasksCount()
      self.tasks.insert(newTask, at: carouselIndex)
      self.addMapPin(task: newTask, carouselIndex: carouselIndex)
    }
    
    self.carouselView.reloadData()
    // add map pin for new task
    // add carousel index
    self.updateMapAnnotationCardIndexes()
    self.clusterManager.reload(self.mapView, visibleMapRect: self.mapView.visibleMapRect)
    // CHECK update all of the map annotation indexes
    
    if self.tasks.count == 2 && self.mTaskDescription == nil && currentUserTaskSaved == false {
      self.carouselView.scrollToItem(at: 1, animated: true)
    }
    self.updateMapAnnotationCardIndexes()
  }
  
  func observeUserLocationAuth()  {
    
    notification = NotificationCenter.default.addObserver(forName: .UIApplicationWillEnterForeground, object: nil, queue: .main) {
      [unowned self] notification in
      self.checkNotificationPermission()
      self.addCurrentUserLocationToFirebase()
      if self.carouselView.currentItemIndex == 0 {
        self.mapView.setUserTrackingMode(.follow, animated: true)
      }
      let authorizationStatus = CLLocationManager.authorizationStatus()
      if (authorizationStatus == .denied || authorizationStatus == .notDetermined) && self.isLocationNotAuthorised  {
        // User has not authorized access to location information.
        self.showLocationAlert()
      }
      self.updateNearBytask()
    }
  }
  
  func sortMessageArray(_ pMessages:NSDictionary) -> [NSDictionary] {
    var messageArray = [NSDictionary]()
    let helper = DateStringFormatterHelper()
    for message in pMessages.allKeys {
      var messageDic =  pMessages[message] as! [String:Any]
      messageDic["dateCreated"] = helper.convertStringToDate(datestring: messageDic["dateCreated"] as! String)
      messageArray.append(messageDic as NSDictionary)
    }
    messageArray.sort {
      item1, item2 in
      let date1 = item1["dateCreated"] as! Date
      let date2 = item2["dateCreated"] as! Date
      return date1.compare(date2) == ComparisonResult.orderedDescending
    }
    return messageArray
  }
  
  
  func removeCarousel(_ index: Int)  {
    UIView.transition(with: carouselView!,
                      duration: 0.3,
                      options: .transitionCrossDissolve,
                      animations: { () -> Void in
                        self.carouselView.itemView(at: index)?.alpha = 0;
    },
                      completion:{ (success) in
                        self.carouselView.removeItem(at: index, animated: true)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                          self.carouselView.reloadData()
                        }
                        
    })
    
    
  }
  
  // Remove marker for tasks
  func removeAnnotationForTask(_ taskID:String) {
    for annotation in self.mapView.annotations {
      
      if annotation is CustomTaskMapAnnotation {
        
        // loops through the tasks array and find the corresponding task
        let customAnnotation = annotation as! CustomTaskMapAnnotation
        
        // check if the task has the same id as the annotation
        if  taskID == customAnnotation.taskUserId {
          self.clusterManager.remove(annotation)
          break
          
        }
        
        
      } else if annotation is CustomFocusTaskMapAnnotation {
        
        // loops through the tasks array and find the corresponding task
        let customAnnotation = annotation as! CustomFocusTaskMapAnnotation
        
        // check if the task has the same id as the annotation
        if  taskID == customAnnotation.taskUserId {
          self.clusterManager.remove(annotation)
          self.mapView.removeAnnotation(annotation)
          break
        }
        
      }
      
    }
    self.clusterManager.reload(self.mapView, visibleMapRect: self.mapView.visibleMapRect)
    
  }
  
  func checkTaskTimeLeft () {
    let currentUserTask = self.tasks[0]
    tasksExpireObserver = self.tasksRef?.child((currentUserTask?.taskID)!).child("timeUpdated").observe(.value, with: { (snapshot) in
      UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["taskExpirationNotification"])
      // reset expiration timer
      self.expirationTimer = nil
      
      // invalidate the current timer
      self.expirationTimer?.invalidate()
      
      if let timeUpdated = snapshot.value as? String {
        
        let dateformatter = DateStringFormatterHelper()
        
        // get current time
        let currentTime = Date()
        
        // get the difference between time created and current time
        var timeDifference = currentTime.seconds(from: dateformatter.convertStringToDate(datestring: timeUpdated))
        
        // if time difference is greater than 1 hour (3600 seconds)
        // return and don't add this task to tasks
        
        if timeDifference > self.SECONDS_IN_HOUR {
          
          currentUserTask?.completed = true;
          currentUserTask?.completeType = Constants.STATUS_FOR_TIME_EXPIRED
          self.tasks[0] = currentUserTask
          //Remove Card
          
          self.tasks[0] = currentUserTask
          self.checkTaskRecentActivity(currentUserTask!, callBack: { (activity) in
            if activity {
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
                self.createMarkCompleteView()
                self.createLocalNotification(title: "Your help quest expired", body: "Did you get help? Remember to thank them!", time: Int(0.0))
                
              }
            } else {
              UserDefaults.standard.set(nil, forKey: Constants.PENDING_TASKS)
              self.newItemSwiped = true
              self.removeTaskAfterComplete(currentUserTask!)
              self.createLocalNotification(title: "Your help quest expired", body: "🕐 Still need help?", time: Int(0.0))
            }
          })
          
        }
        else {
          timeDifference = self.SECONDS_IN_HOUR - timeDifference
          self.startTimer(timeDifference)
          self.createLocalNotification(title: "Hey! No activity is there from long time", body: "Click to chat with nearby people", time: timeDifference)
          
        }
      }
    })
    
  }
  
  
  //Start timer to change user location icon
  func startUpdationForUserLocation()  {
    self.locationUpdateTimer =  Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (Timer) in
      for annotation in self.mapView.annotations {
        if annotation is CustomUserMapAnnotation {
          let annotationCustom = annotation as! CustomUserMapAnnotation
          let viewAnnotation = self.mapView.view(for: annotation)
          let imageAnnotation = self.getUserLocationImage(Date().seconds(from: annotationCustom.lastUpdatedTime ?? Date()))
          if imageAnnotation != nil {
            viewAnnotation?.image = imageAnnotation
          }
          else {
            UIView.animate(withDuration: 0.5, animations: {
              viewAnnotation?.alpha = 0.0
            }, completion: { (isCompleted) in
              self.mapView.removeAnnotation(annotation)
            })
          }
        }
      }
      
    }
  }
  
  
  // Start timer for one hour (Task Expiration)
  func startTimer(_ interval :Int)  {
    // save current user task description to check if its
    // the same when timer is done
    
    // reset expiration timer
    self.expirationTimer = nil
    
    // invalidate the current timer
    self.expirationTimer?.invalidate()
    // start timer to check if it has expired
    self.expirationTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(interval), repeats: false) { (Timer) in
      
      // finish deleting task
      if self.tasks.count == 0 {
        return
      }
      // get the current user's task
      let currentUserTask = self.tasks[0]
      
      // if the current user's task has not been completed
      // and it is the same task (don't notify expiration if its a different task)
      if currentUserTask?.completed != true && currentUserTask?.userId == self.currentUserId {
        
        // create notification that the task is out of time
        currentUserTask?.completed = true;
        currentUserTask?.completeType = Constants.STATUS_FOR_TIME_EXPIRED
        self.tasks[0] = currentUserTask
        //Check Recent Activity
        self.checkTaskRecentActivity(currentUserTask!, callBack: { (activity) in
          if activity {
            self.createMarkCompleteView()
            self.createLocalNotification(title: "Your help quest expired", body: "Did you get help? Remember to thank them!", time: Int(0.0))
          } else {
            UserDefaults.standard.set(nil, forKey: Constants.PENDING_TASKS)
            self.newItemSwiped = true
            self.removeTaskAfterComplete(currentUserTask!)
            self.createLocalNotification(title: "Your help quest expired", body: "🕐 Still need help?", time: Int(0.5))
          }
        })
        // reset the current user's task
        // delete the task if it has expired
        // self.deleteAndResetCurrentUserTask()
        
        // remove own annotation on the map
        //  self.removeCurrentUserTaskAnnotation()
        
      }
      
      // reset expiration timer
      self.expirationTimer = nil
      
      // invalidate the current timer
      Timer.invalidate()
    }
  }
  
  //Start updating location at Significant Changes
  func startReceivingSignificantLocationChanges() {
    let authorizationStatus = CLLocationManager.authorizationStatus()
    if authorizationStatus != .authorizedAlways {
      // User has not authorized access to location information.
      return
    }
    
    if !CLLocationManager.significantLocationChangeMonitoringAvailable() {
      // The service is not available.
      return
    }
    locationManager.delegate = self
    locationManager.stopUpdatingHeading()
    locationManager.stopUpdatingLocation()
    locationManager.startMonitoringSignificantLocationChanges()
  }
  
  func removeFirebaseLoader() {
    
    if self.isLoadingFirebase != false {
      self.isLoadingFirebase = false
      if (self.userLatitude != nil && self.userLongitude != nil) {
        // TODO fix
        let timeStamp = Int(NSDate.timeIntervalSinceReferenceDate*1000)
        self.tasks.append(
          Task(userId: self.currentUserId!, taskDescription: "", latitude: self.userLatitude!, longitude: self.userLongitude!, completed: false, timeCreated: Date(), timeUpdated: Date(), taskID: "\(timeStamp)", recentActivity: false, userMovedOutside: false)
        )
        self.carouselView.insertItem(at: 1, animated: true)
      }
      self.tasks.remove(at: 0)
      self.carouselView.removeItem(at: 0, animated: true)
      self.carouselView.reloadItem(at: 0, animated: false)
      //self.carouselView.perform(#selector(self.carouselView.reloadData), with: nil, afterDelay: 0.1)
    }
    self.indicatorView.isHidden = true
  }
  
  func startLoderAnimation() {
    if let animationView = self.view.viewWithTag(self.LOADER_VIEW) {
      animationView.alpha = 0.3
      UIView.animate(withDuration: 1, delay: 0, options: [.repeat,.autoreverse], animations: {
        animationView.alpha = 0.8
      }, completion: nil)
    }
  }
  
  // Show Notification Alert
  func showNotificationAlert() {
    if mShowNotification {
      CMAlertController.sharedInstance.showAlert(nil, Constants.sTASK_CREATE_NOTIFICATION_ERROR, ["Not now", "Sure"]) { (sender) in
        if let button = sender {
          if button.tag == 1 {
            self.mShowNotification = false
            requestForNotification()
          }
        }
      }
    }
  }
  
  func checkNotificationPermission() {
    checkStatusOfNotification { (status) in
      if status == .notDetermined {
        self.mShowNotification = true
      } else {
        self.mShowNotification = false
      }
    }
  }
  
  //get Previous Task saved in user Defaults
  func getPreviousTask()  {
    if (UserDefaults.standard.object(forKey: Constants.PENDING_TASKS) != nil) {
      //Decode data
      let currentTaskData = UserDefaults.standard.object(forKey: Constants.PENDING_TASKS)
      if let task = currentTaskData as? Data {
        
        if  let dicTask = NSKeyedUnarchiver.unarchiveObject(with: task as! Data) as? Dictionary<String, Any> {
          let userID = dicTask["userId"] as! String
          let taskDescription = dicTask["taskDescription"] as! String
          let latitude = dicTask["latitude"] as! CLLocationDegrees
          let longitude = dicTask["longitude"] as! CLLocationDegrees
          let completed = dicTask["completed"] as! Bool
          let startColor =  dicTask["startColor"] as! String
          let endColor =  dicTask["endColor"] as! String
          let timeCreated = dicTask["timeCreated"] as! Date
          let timeUpdated = dicTask["timeUpdated"] as! Date
          let taskID = dicTask["taskID"] as! String
          let recentActivity = dicTask["recentActivity"] as! Bool
          let userMovedOutside = dicTask["userMovedOutside"] as! Bool
          
          let currentTask =  Task(userId: userID , taskDescription: taskDescription , latitude: latitude , longitude: longitude, completed: completed, timeCreated: timeCreated , timeUpdated: timeUpdated, taskID: taskID, recentActivity: recentActivity, userMovedOutside: userMovedOutside)
          currentTask.startColor = startColor
          currentTask.endColor = endColor
          
          
          // get current time
          let currentTime = Date()
          
          // get the difference between time created and current time
          let timeDifference = currentTime.seconds(from: currentTask.timeCreated)
          print("time difference for task: \(timeDifference)")
          
          //                            self.newItemSwiped = true
          self.currentUserTaskSaved = true
          self.tasks.append(currentTask)
          
          //add new annotation to the map for the current user's task
          let currentUserMapTaskAnnotation = CustomCurrentUserTaskAnnotation(currentCarouselIndex: 0)
          // set location for the annotation
          currentUserMapTaskAnnotation.coordinate = CLLocationCoordinate2DMake(currentTask.latitude, currentTask.longitude)
          self.mapView.addAnnotation(currentUserMapTaskAnnotation)
          
          setUpGeofenceForTask(currentTask.latitude, currentTask.longitude)
          carouselView.reloadData()
          checkTaskTimeLeft()
          //}
          
        }
        else {
          self.currentUserTaskSaved = false
          isLoadingFirebase = true
        }
        
      }
    }
    else {
      self.currentUserTaskSaved = false
      isLoadingFirebase = true
    }
  }
  
  
  //MARK:- Firebase Updation
  
  func checkTaskParticipation(_ pTask : Task, callBack:@escaping (_ participation: Bool) -> ()) {
    usersRef?.child((FIRAuth.auth()?.currentUser?.uid)!).child("taskParticipated").child("tasks").observeSingleEvent(of: .value, with: { (snapshot) in
      if let tasksParticipated = snapshot.value as? [String] {
        if tasksParticipated.contains(pTask.taskID!) {
          callBack(true)
        } else {
          callBack(false)
        }
      } else {
        callBack(false)
      }
    })
    
  }
  
  func checkTaskRecentActivity(_ pTask : Task, callBack:@escaping (_ completed: Bool) -> ()) {
    self.tasksRef?.child((pTask.taskID)!).child("recentActivity").observeSingleEvent(of: .value, with: { (snapshot) in
      if let activity = snapshot.value as? Bool {
        callBack(activity)
      } else {
        callBack(false)
      }
    })
    
  }
  
  //update last 5 locations at backend
  func UpdateUserLocationServer()  {
    self.usersRef?.child(currentUserId!).child("location").observeSingleEvent(of: .value, with: { (snapshot) in
      
      let dateformatter = DateStringFormatterHelper()
      let stringDate = dateformatter.convertDateToString(date: NSDate() as Date)
      
      let location = ["lat" : self.locationManager.location?.coordinate.latitude ?? 0,
                      "long" : self.locationManager.location?.coordinate.longitude ?? 0,
                      "updatedAt" : stringDate ] as [String : Any]
      
      
      if var lastLocations = snapshot.value as? [Any] {
        // append location if any
        if lastLocations.count >= self.CHAT_HISTORY {
          lastLocations.removeFirst()
          lastLocations.append(location)
          self.setUserinfo(lastLocations, "location",self.currentUserId!)
        }
        else {
          lastLocations.append(location)
          self.setUserinfo(lastLocations, "location",self.currentUserId!)
          
        }
      }
      else {
        self.setUserinfo([location], "location",self.currentUserId!)
      }
      
    })
  }
  
  //Update information At Firebase
  func setUserinfo(_ Value: [Any], _ child :String , _ user : String)  {
    self.usersRef?.child(user).child(child).setValue(Value)
    
  }
  
  //update Friends at user Nodes
  func addFriend(_ friendID:String)  {
    self.usersRef?.child(self.currentUserId!).child("friends").observeSingleEvent(of: .value, with: { (snapshot) in
      if var arrFriends = snapshot.value as? [String] {
        if !arrFriends.contains(friendID) {
          arrFriends.append(friendID)
          self.usersRef?.child(self.currentUserId!).child("friends").setValue(arrFriends)
        }
      }
      else {
        self.usersRef?.child(self.currentUserId!).child("friends").setValue([friendID])
      }
      
    })
    
  }
  
  //Update points at Firebase Server
  func UpdatePointsServer(_ points:Int, _ user : String)  {
    let currentUserTask = self.tasks[0];
    self.usersRef?.child(user).child("scoreDetail").observeSingleEvent(of: .value, with: { (snapshot) in
      
      //Convert date to String
      let dateformatter = DateStringFormatterHelper()
      let stringDate = dateformatter.convertDateToString(date: NSDate() as Date)
      
      var dicPoints = Dictionary<String, Any>()
      dicPoints["points"] = points
      dicPoints["taskID"] = currentUserTask?.taskID
      dicPoints["createdDate"] = stringDate
      if var points = snapshot.value as? [Any] {
        points.append(dicPoints)
        self.setUserinfo(points, "scoreDetail", user)
      }
      else {
        self.setUserinfo([dicPoints], "scoreDetail", user)
      }
      
    })
  }
  
  // Remove task and Update completeion details at Firebase
  func removeTaskAfterComplete(_ currentUserTask: Task)  {
    
    let taskMessage = currentUserTask.taskDescription
    print("taskMessage \(currentUserTask.taskDescription) \(taskMessage)")
    
    //Send Push notification If task is Completed
    //filter Admin and thank users users
    if currentUserTask.completeType == Constants.STATUS_FOR_THANKED || currentUserTask.completeType == Constants.STATUS_FOR_NOT_HELPED {
      self.channelsRef?.child(currentUserTask.taskID!).child("users").observeSingleEvent(of: .value, with: { (snapshot) in
        if  let users = snapshot.value as? Dictionary<String , Any> {
          
          for user in Array(users.keys) {
            if !Array(self.usersToThank.keys).contains(user) && self.currentUserId != user {
              self.usersRef?.child(user).child("deviceToken").observeSingleEvent(of: .value, with: { (snapshot) in
                if  let token = snapshot.value as? String {
                  PushNotificationManager.sendNotificationToDevice(deviceToken: token, channelId: currentUserTask.taskID!, taskMessage: taskMessage)
                }
              })
            }
          }
          // reset the dictionary
          self.usersToThank = [:]
        }
      })
      
    }
    else {
      // reset the dictionary
      self.usersToThank = [:]
    }
    
    //remove observer for time
    if tasksExpireObserver != nil {
      self.tasksRef?.child(currentUserTask.taskID!).child("timeUpdated").removeObserver(withHandle: tasksExpireObserver!)
    }
    //reload Carousel
    if self.tasks.count > 0 {
      self.tasks.remove(at: 0)
    }
    
    let timeStamp = Int(NSDate.timeIntervalSinceReferenceDate*1000)
    let currentUserKey = FIRAuth.auth()?.currentUser?.uid
    
    if self.tasks.count > 0 && self.tasks[0]?.taskDescription != "" {
      self.newItemSwiped = true
      self.tasks.insert(Task(userId: currentUserKey!, taskDescription: "", latitude: (self.locationManager.location?.coordinate.latitude) ?? self.userLatitude! , longitude: (self.locationManager.location?.coordinate.longitude) ?? self.userLongitude! , completed: false, taskID: "\(timeStamp)", recentActivity: false, userMovedOutside: false), at: 0)
    }
    currentUserTaskSaved = false
    //      self.carouselView.insertItem(at: 0, animated: true)
    self.carouselView.reloadData()
    //        self.carouselView.reloadItem(at: 0, animated: true)
//    currentUserTask.updateFirebaseTask()
    // Update task as Complete
    // create new date formatter
    let dateformatter = DateStringFormatterHelper()
    
    // convert timeCreated and timeUpdated to string
    let updateDate = dateformatter.convertDateToString(date: Date())
    
    let taskUpdate = ["completed": currentUserTask.completed ,
                      "createdby": currentUserTask.userId ,
                      "endColor": currentUserTask.endColor ?? "",
                      "startColor": currentUserTask.startColor ?? "",
                      "taskDescription": currentUserTask.taskDescription ,
                      "taskID": currentUserTask.taskID ?? "",
                      "timeCreated": currentUserTask.timeCreatedString ,
                      "timeUpdated": updateDate,
                      "completeType": currentUserTask.completeType ?? "",
                      "helpedBy": currentUserTask.helpedBy ?? "",
                      "userMovedOutside" : currentUserTask.userMovedOutside  ,
                      "recentActivity" : currentUserTask.recentActivity
      ] as [String : Any];
    
    self.tasksRef?.child(currentUserTask.taskID!).setValue(taskUpdate)
    
    UserDefaults.standard.set(nil, forKey: Constants.PENDING_TASKS)
    
  }
  
  //update Task views count at firebase
  func updateViewsCount(_ taskID : String)  {
    taskViewRef?.child(taskID).observeSingleEvent(of: .value, with: { (snapshot) in
      if let arrTasksdetail = snapshot.value as? [String : Any] {
        if var taskViews = arrTasksdetail["users"] as? [String] {
          if !taskViews.contains( self.currentUserId!) {
            taskViews.append(self.currentUserId!)
            let tasksViewUpdate =  ["users" : taskViews, "count":taskViews.count] as [String : Any];
            // update at server
            self.taskViewRef?.child(taskID).setValue(tasksViewUpdate)
          }
        }
        else {
          let tasksViewUpdate =  ["users" : [self.currentUserId], "count":1] as [String : Any];
          // update at server
          self.taskViewRef?.child(taskID).setValue(tasksViewUpdate)
        }
      }
      else {
        let tasksViewUpdate =  ["users" : [self.currentUserId], "count":1] as [String : Any];
        // update at server
        self.taskViewRef?.child(taskID).setValue(tasksViewUpdate)
      }
    })
  }
  
  func removeHistoryTasks() {
    
    // user Moved to another place
    self.nearbyUsers.removeAll()
    //remove all users
    self.mapView.annotations.forEach {
      if ($0 is CustomUserMapAnnotation) {
        self.mapView.removeAnnotation($0)
      }
    }
    self.tasks = self.tasks.filter {
      return $0?.completed == false
    }
    print(self.tasks.count);
    self.carouselView.reloadData()
  }
  
  func updateNearBytask() {
    self.removeHistoryTasks()
    if self.userLatitude == nil && self.userLongitude == nil { return }
    //remove user observers
    self.usersCircleQuery?.removeObserver(withFirebaseHandle: self.usersExitCircleQueryHandle!)
    self.usersCircleQuery?.removeObserver(withFirebaseHandle: self.usersEnterCircleQueryHandle!)
    self.usersCircleQuery?.removeObserver(withFirebaseHandle: self.usersMovedCircleQueryHandle!)
    self.queryUsersAroundCurrentLocation(latitude: self.userLatitude!, longitude: self.userLongitude!)
    
    //task Moved to new Location
    self.tasksCircleQuery?.removeObserver(withFirebaseHandle: self.tasksDeletedCircleQueryHandle!)
    self.tasksCircleQuery?.removeObserver(withFirebaseHandle: self.tasksCircleQueryHandle!)
    self.queryTasksAroundCurrentLocation(latitude: self.userLatitude!, longitude: self.userLongitude!)
  }
}

// MARK: carousel view
extension MainViewController: iCarouselDelegate, iCarouselDataSource {
  
  func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
    
    print("index hit: \(index)")
    let viewWidth  = UIScreen.main.bounds.size.height <= 568 ? 286 : 335 //335
    if index == 0 && isLoadingFirebase == true  {
      let tempView = UIView(frame: CGRect(x: 0, y: 0, width: viewWidth, height:Int(carousel.frame.size.height-50)))
      tempView.backgroundColor = UIColor.white
      tempView.tag = self.LOADER_VIEW
      tempView.layer.shadowColor = UIColor.black.cgColor
      tempView.layer.shadowOffset = CGSize(width: 0, height: 10)  //Here you control x and y
      tempView.layer.shadowOpacity = 0.3
      tempView.layer.shadowRadius = 15.0 //Here your control your blur
      tempView.layer.masksToBounds =  false
      tempView.alpha = 0.3
      // add temp view to shadow view
      let shadowView = UIView(frame: CGRect(x: 0, y: 0, width: viewWidth, height: Int((carousel.frame.size.height-50)+20)))
      shadowView.backgroundColor = UIColor.clear
      shadowView.layer.shadowColor = UIColor.black.cgColor
      shadowView.layer.shadowOffset = CGSize(width: 0, height: 10)
      shadowView.layer.shadowOpacity = 0.3
      shadowView.layer.shadowRadius = 15.0
      
      shadowView.addSubview(tempView)
      
      return shadowView
    }
    
    // width 335
    // 1st card if user didn't swipe for new task
    if index == 0 && !self.newItemSwiped && self.tasks.count > 1 && self.currentUserTaskSaved == false && canCreateNewtask == true {
      
      let tempView = UIView(frame: CGRect(x: 0, y: 0, width: viewWidth, height:Int(carousel.frame.size.height-50)))
      tempView.backgroundColor = UIColor.clear
      
      tempView.layer.shadowColor = UIColor.black.cgColor
      tempView.layer.shadowOffset = CGSize(width: 0, height: 10)  //Here you control x and y
      tempView.layer.shadowOpacity = 0.3
      tempView.layer.shadowRadius = 15.0 //Here your control your blur
      tempView.layer.masksToBounds =  false
      
      return tempView
      
    }
    
    // if there is only 1 card and no surrounding cards
    // show the first card
    
    // 1st task if user swiped for new task or there is no other tasks
    if (index == 0 && (self.newItemSwiped || self.currentUserTaskSaved) ) || self.tasks.count <= 1 {
      // setup temporary view as gradient view
      
      //carousel.frame.size.height-15
      let tempView = GradientView(frame: CGRect(x: 0, y: 0, width: viewWidth, height:Int(carousel.frame.size.height-50)))
      
      
      // get the first task
      let task = self.tasks[index] as! Task
      let cardColor = CardColor()
      // if it already has start and end color, use it start and end color for the tempview
      if let taskStartColor = task.startColor, let taskEndColor = task.endColor {
        
        tempView.startColor = UIColor.hexStringToUIColor(hex: taskStartColor)
        tempView.endColor = UIColor.hexStringToUIColor(hex: taskEndColor)
        // if the task doesn't have a start and end color yet
        // use the start and end color to save it
      } else {
        let randomColorGradient = cardColor.generateRandomColor()
        
        // save task random colors to task
        let randomStartColor = randomColorGradient[0]
        let randomEndColor = randomColorGradient[1]
        
        task.startColor = randomStartColor
        task.endColor = randomEndColor
        
        self.tasks[index] = task
        
        // use task's start and end color for the view
        tempView.startColor = UIColor.hexStringToUIColor(hex: randomStartColor)
        tempView.endColor = UIColor.hexStringToUIColor(hex: randomEndColor)
        
        
      }
      
      // width 8.5/10
      //setup textView for gradient viwe
      let textView = UITextView(frame: CGRect(x: 0, y: 0, width: (tempView.bounds.width*0.9), height: (carousel.frame.size.height-50)*3/4))
      textView.textColor = UIColor.white
      textView.contentInset = UIEdgeInsets(top: 15, left: 0, bottom: 0, right: 0)
      // turn off auto correction
      textView.autocorrectionType = .no
      textView.showsVerticalScrollIndicator = false
      textView.showsHorizontalScrollIndicator = false
      
      // if current user has saved task
      // their task description
      if self.currentUserTaskSaved  {
        textView.alpha = 1
        textView.text = task.taskDescription
        
        // disable editing
        textView.isEditable = false
      } else {
        
        // enable editing
        textView.isEditable = true
        
        // show placeholder
        if let prevDescription = mTaskDescription {
          textView.text = prevDescription
          textView.alpha = 1
        } else {
          textView.text = "What do you need help with?"
          textView.alpha = 0.5
        }
        //textView.becomeFirstResponder()
        
      }
      
      textView.center.x = tempView.center.x
      textView.backgroundColor = UIColor.clear
      textView.textAlignment = .left
      let fontSize  = UIScreen.main.bounds.size.height <= 568 ? 20 : 24
      textView.font = UIFont.systemFont(ofSize: CGFloat(fontSize))
      textView.delegate = self
      textView.isScrollEnabled = false
      textView.tag = CURRENT_USER_TEXTVIEW_TAG
      tempView.addSubview(textView)
      
      
      // if the user has saved their task
      // rendr message button
      if currentUserTaskSaved {
        let messageView = UIButton(frame: CGRect(x: (tempView.bounds.width * 1/4), y: (tempView.bounds.height * 3/4), width: 24, height: 24))
        messageView.setImage(UIImage(named: "messageImage"), for: .normal)
        messageView.addTarget(self, action: #selector(goToChat(sender:)), for: .touchUpInside)
        
        tempView.addSubview(messageView)
        
      } else {
        // if user has not saved task
        // show close button
        let closeView = UIButton(frame: CGRect(x: (tempView.bounds.width * 1/4), y: (tempView.bounds.height * 3/4), width: 24, height: 24))
        closeView.setImage(UIImage(named: "close"), for: .normal)
        closeView.addTarget(self, action: #selector(discardCurrentUserTask(sender:)), for: .touchUpInside)
        closeView.tag = self.CURRENT_USER_CANCEL_BUTTON
        if mTaskDescription != nil {
          closeView.alpha = 1
          closeView.isEnabled = true
        } else {
          closeView.alpha = 0.5
          closeView.isEnabled = false
        }
        
        // check if there are more than 1 card
        // if there is only 1 card disable the close button
        
        
        tempView.addSubview(closeView)
      }
      
      
      var doneView: UIButton?
      
      // if current user task saved
      // complete the task
      if self.currentUserTaskSaved {
        
        // add done view to finish or save the task
        doneView = UIButton(frame: CGRect(x: (tempView.bounds.width * 3/4), y: (tempView.bounds.height * 3/4), width: 24, height: 24))
        doneView?.setImage(UIImage(named: "check"), for: .normal)
        doneView?.addTarget(self, action: #selector(self.markTaskAsComplete), for: .touchUpInside)
        tempView.addSubview(doneView!)
        
      } else {
        
        
        // create doneview that says post
        // and allows user to post their message
        doneView = UIButton(frame: CGRect(x: (tempView.bounds.width * 3/4 - 20), y: (tempView.bounds.height * 3/4), width: 50, height: 24))
        doneView?.setTitle("Post", for: .normal)
        // disable the post button at first
        if mTaskDescription != nil {
          doneView?.isEnabled = true
          doneView?.alpha = 1
        }
        else {
          doneView?.isEnabled = false
          doneView?.alpha = 0.5
        }
        
        doneView?.tag = self.POST_NEW_TASK_BUTTON_TAG
        //change the opacity to 0.5 for the button at first
        let fontSize  = UIScreen.main.bounds.size.height <= 568 ? 20 : 24
        doneView?.titleLabel?.font = UIFont.systemFont(ofSize: CGFloat(fontSize))
        doneView?.addTarget(self, action: #selector(createTaskForCurrentUser(sender:)), for: .touchUpInside)
        tempView.addSubview(doneView!)
        
      }
      
      
      // add temp view to shadow view
      let shadowView = UIView(frame: CGRect(x: 0, y: 0, width: viewWidth, height: Int((carousel.frame.size.height-50)+20)))
      shadowView.backgroundColor = UIColor.clear
      shadowView.layer.shadowColor = UIColor.black.cgColor
      shadowView.layer.shadowOffset = CGSize(width: 0, height: 10)
      shadowView.layer.shadowOpacity = 0.3
      shadowView.layer.shadowRadius = 15.0
      
      shadowView.addSubview(tempView)
      
      // add instructions for "Automatically expires in 1hr or if you leave the area" at bottom label
      let bottomNoticeLabel = UILabel(frame: CGRect(x: 0, y: 10, width: viewWidth, height: 20))
      bottomNoticeLabel.textColor = UIColor.white
      bottomNoticeLabel.text = "Automatically expires in 1hr or if you leave the area"
      bottomNoticeLabel.textAlignment = .center
      bottomNoticeLabel.font = UIFont.init(name: Constants.FONT_NAME, size: 13)
      bottomNoticeLabel.numberOfLines = 1
      bottomNoticeLabel.adjustsFontSizeToFitWidth = true
      bottomNoticeLabel.minimumScaleFactor = 0.5
      bottomNoticeLabel.center.x = tempView.center.x
      bottomNoticeLabel.center.y = tempView.bounds.maxY + 12
      shadowView.addSubview(bottomNoticeLabel)
      
      return shadowView
    }
    
    // if index out of bound
    if (index >= (self.tasks.count)) {
      // create invisible card
      print("clear card created")
      let tempView = UIView(frame: CGRect(x: 0, y: 0, width: viewWidth, height:Int(carousel.frame.size.height-50)))
      tempView.backgroundColor = UIColor.clear
      tempView.layer.masksToBounds = false
      return tempView
    } else {
      
      // STANDARD VIEW - for most cards
      
      // get the corresponding task
      let task = self.tasks[index] as! Task
      
      // setup temporary view as gradient view
      let tempView = GradientView(frame: CGRect(x: 0, y: 0, width: viewWidth, height:Int(carousel.frame.size.height-50)))
      let placeholderView = UIView(frame: CGRect(x: 0, y: 0, width: viewWidth, height:Int(carousel.frame.size.height-50)))
      let cardColor = CardColor()
      
      // if task doesn't have a  start color and end color
      // create random colors for it
      if (task.startColor == nil) || (task.endColor == nil) {
        
        // get random star and end colors
        let randomColorGradient = cardColor.generateRandomColor()
        
        // save the colors to the task
        task.setGradientColors(startColor: randomColorGradient[0], endColor: randomColorGradient[1])
        if task.taskDescription != "" {
          task.save(self)
        }
        
        
        // set the color gradient colors for the card
        tempView.startColor = UIColor.hexStringToUIColor(hex: randomColorGradient[0])
        tempView.endColor = UIColor.hexStringToUIColor(hex: randomColorGradient[1])
      } else {
        
        // else
        // use the colors that are already saved for the task
        if task.completed == true && task.taskDescription != "" {
          tempView.startColor = UIColor.hexStringToUIColor(hex: cardColor.expireCard[0])
          tempView.endColor = UIColor.hexStringToUIColor(hex: cardColor.expireCard[1])
          tempView.alpha = 0.6
        } else {
          tempView.startColor = UIColor.hexStringToUIColor(hex: task.startColor!)
          tempView.endColor = UIColor.hexStringToUIColor(hex: task.endColor!)
        }
        
      }
      
      // setup label for gradient view
      let label = UILabel(frame: CGRect(x: 0, y: 0, width: (tempView.bounds.width*0.9), height: (carousel.frame.size.height-50)*3/4))
      label.lineBreakMode = NSLineBreakMode.byWordWrapping
      label.numberOfLines = 4
      label.text = task.taskDescription
      label.textAlignment = .left
      
      //label.center.x = tempView.center.x
      //label.center.y = tempView.bounds.minY + 50
      
      //align label to the left side of the card
      label.translatesAutoresizingMaskIntoConstraints = false
      // create constraints
      let horizontalConstraint = NSLayoutConstraint(item: label, attribute: .leading, relatedBy: NSLayoutRelation.equal, toItem: placeholderView, attribute: .leading, multiplier: 1, constant: 20)
      let verticalConstraint = NSLayoutConstraint(item: label, attribute: .top, relatedBy: NSLayoutRelation.equal, toItem: placeholderView, attribute: .top, multiplier: 1, constant: 20)
      let widthConstraint = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: (tempView.bounds.width*0.9))
      let fontSize  = UIScreen.main.bounds.size.height <= 568 ? 20 : 24
      label.font = UIFont.systemFont(ofSize: CGFloat(fontSize))
      label.textColor = UIColor.white
      placeholderView.addSubview(label)
      // add edge constraints to the label
      placeholderView.addConstraints([horizontalConstraint, verticalConstraint,  widthConstraint])
      
      
      // setup clickable button for gradient view
      let messageButton = UIButton(frame: CGRect(x: 0, y: (carousel.frame.size.height-50)*3/4, width: 150, height: 20))
      messageButton.center.x = tempView.center.x
      var messageImage : UIImage?
      
      if task.completed == false {
        messageButton.setTitle("I can help", for: .normal)
        messageImage = UIImage(named: "messageImage") as UIImage?
      } else {
        messageImage = #imageLiteral(resourceName: "completeMessage")
      }
      
      messageButton.setImage(messageImage, for: .normal)
      messageButton.imageView?.contentMode = .scaleAspectFit
      messageButton.setTitleColor(UIColor.darkGray, for: .highlighted)
      messageButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
      messageButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
      messageButton.addTarget(self, action: #selector(goToChat(sender:)), for: .touchUpInside)
      messageButton.alpha = 1.0
      messageButton.tintColor = UIColor.white
      if task.taskDescription != ONBOARDING_TASK_1_DESCRIPTION && task.taskDescription != ONBOARDING_TASK_3_DESCRIPTION {
        placeholderView.addSubview(messageButton)
      }
      
      // add temp view to shadow view
      
      
      let shadowView = UIView(frame: CGRect(x: 0, y: 0, width: Int(viewWidth), height: Int((carousel.frame.size.height-50)+20)))
      shadowView.backgroundColor = UIColor.clear
      shadowView.layer.shadowColor = UIColor.black.cgColor
      shadowView.layer.shadowOffset = CGSize(width: 0, height: 20)
      shadowView.layer.shadowOpacity = 0.3
      shadowView.layer.shadowRadius = 15.0
      shadowView.alpha = 1.0
      
      
      shadowView.addSubview(tempView)
      shadowView.addSubview(placeholderView)
      
      
      // create label to show how long ago it was created
      let bottomLabel = UILabel(frame: CGRect(x: 20, y: 0, width: shadowView.frame.size.width-40, height: 30))
      // use Moment to get the time ago for task at current index
      let taskTimeCreated = moment((self.tasks[index]?.timeCreated)!)
      // set label with time ago "x min ago"
      bottomLabel.textAlignment = .center
      bottomLabel.center.x = tempView.center.x
      let tempViewBottom = tempView.bounds.maxY
      bottomLabel.center.y = tempViewBottom + 12
      bottomLabel.font = UIFont.init(name: Constants.FONT_NAME, size: 13)
      bottomLabel.numberOfLines = 1
      bottomLabel.adjustsFontSizeToFitWidth = true
      bottomLabel.minimumScaleFactor = 0.5
      bottomLabel.textColor = UIColor.white
      bottomLabel.alpha = 1.0
      var textTaskCreatedTime = "\(taskTimeCreated.fromNow())"
      if task.completed == true {
        textTaskCreatedTime = "Completed \(textTaskCreatedTime)"
      }
      
      bottomLabel.text = textTaskCreatedTime
      
      // add bottom label to shadow view
      shadowView.addSubview(bottomLabel)
      return shadowView
    }
    
  }
  
  func onboardingTaskSwiped(_:UIGestureRecognizer) {
    // check if current card is an onboarding card
    let currentCardIndex = self.carouselView.currentItemIndex
    // if it is delete it
    self.lastCardIndex  = currentCardIndex
    //        self.checkAndRemoveOnboardingTasks(carousel: self.carouselView, cardIndex: currentCardIndex)
  }
  
  // completion function for check mark
  func markTaskAsComplete(){
    
    // show the alert that completes the quest
    self.showAlertForCompletion()
  }
  
  func showAlertForCompletion() {
    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    let actionCancel = UIAlertAction(title: "Cancel", style: .cancel) { (action:UIAlertAction) in
      //This is called when the user presses the cancel button.
      print("You've pressed the cancel button")
    }
    let actionMarkAsComplete = UIAlertAction(title: "Mark quest as done", style: .default) { (action:UIAlertAction) in
      //This is called when the user presses the complete button.
      self.createMarkCompleteView()
    }
    alert.addAction(actionMarkAsComplete)
    alert.addAction(actionCancel)
    
    self.present(alert, animated: true, completion:nil)
    
  }
  
  func createMarkCompleteView() {
    //Remove Notification
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["taskExpirationNotification"])
    // let users know it was completed
    let currentUserTask = self.tasks[0] as! Task
    let currentUserKey = FIRAuth.auth()?.currentUser?.uid
    
    // get the channel's last messages for each user and then delete
    // the task, conversation channel, and location
    self.channelsRef?.child(currentUserTask.taskID!).observeSingleEvent(of: .value, with: { (snapshot) in
      
      // Get value for snapshot
      let value = snapshot.value as? NSDictionary
      let users = value?["users"] as? NSDictionary ?? [:]
      let messages = value?["messages"] as? NSDictionary ?? [:]
      
      print("conversation channel value: \(value)")
      print("users \(users)")
      print("messages \(messages) keys \(messages.allKeys)")
      //let username = value?["username"] as? String ?? ""
      let messagesSorted = self.sortMessageArray(messages)
      var usersMessagesDictionary: [String:Any] = [:]
      for userKey in users.allKeys{
        
        if let userKeyString = userKey as? String {
          if userKeyString == currentUserKey! {
            // if the user key is the same as the current user
            // continue to next iteration of loop
            continue
          }
          
          // if the current userkey is not the current user
          // use it to find the last message for this user
          // add the user key and message to usermessages dictionary
          for messageKey in messagesSorted {
            // let message = messages[messageKey] as? [String: String]
            if userKeyString == messageKey["senderId"] as! String {
              
              // we found last message for this user,
              // add data to users messages dictionary
              usersMessagesDictionary[userKeyString] = messageKey
              break
            }
          }
          
        }
        
      }
      
      //set textView back to editable
      if let currentUserTextView = self.view.viewWithTag(self.CURRENT_USER_TEXTVIEW_TAG) as? UITextView {
        currentUserTextView.isEditable = true
      }
      
      // get start and end color from card
      let shadowView = self.carouselView.itemView(at: 0) as! UIView
      let gradientView = shadowView.subviews[0] as! GradientView
      let startColor = gradientView.startColor
      let endColor = gradientView.endColor
      
      // make carousel view invisible
      self.carouselView.isHidden = false
      
      // complete the current task
      self.newItemSwiped = true
      
      // remove task annotation on mapview
      self.removeCurrentUserTaskAnnotation()
      
      self.carouselView.reloadItem(at: 0, animated: false)
      
      // create shadow view for completion view
      let completionShadowView = self.createCompletionShadowView()
      
      // finish present view to select who helped you
      let completionView = self.createCompletionGradientView(startColor: startColor, endColor: endColor)
      
      // add text label to ask who helped the user
      let completionLabel = self.createCompletionViewLabel(completionView: completionView)
      
      // loop through dictionary of users helped messages
      // maximum of 5 messages
      var count = 0
      for (userKey, userMessage) in usersMessagesDictionary {
        // loop through the dictionary and create
        // a button with message for each of the users up to 5
        let message = userMessage as! NSDictionary
        if count < 5 {
          //create a button view and add it to the completion view
          let chatUserMessageButton = self.createMessageToThankUser(messageText: message["text"] as! String , completionView: completionView, tagNumber: count, userId: userKey)
          let lineView = UIView(frame: CGRect(x:      -3,
                                              y:      chatUserMessageButton.frame.size.height-5,
                                              width:  chatUserMessageButton.frame.size.width+4,
                                              height: 5.0))
          
          lineView.backgroundColor = UIColor.hexStringToUIColor(hex: Constants.chatBubbleColors[Int(message["colorIndex"] as! String)!])
          chatUserMessageButton.clipsToBounds = true;
          chatUserMessageButton.addSubview(lineView)
          
          
          completionView.addSubview(chatUserMessageButton)
          // update the count
          count+=1
        } else {
          break
        }
      }
      
      
      
      // add smiley face button for people who helped
      let usersHelpedButton = self.createUsersHelpedButton(completionView: completionView)
      
      // add frowney face button for no one helped
      let usersNoHelpButton = self.createUsersNoHelpButton(completionView: completionView)
      
      // add subviews to view
      completionView.addSubview(usersHelpedButton)
      completionView.addSubview(usersNoHelpButton)
      completionView.addSubview(completionLabel)
      
      // TODO add slide up animation
      completionShadowView.addSubview(completionView)
      self.view.addSubview(completionShadowView)
      
      
    }) { (error) in
      print(error.localizedDescription)
    }
  }
  
  func createCompletionShadowView() -> UIView {
    let completionShadowView = UIView(frame: CGRect(x: 0, y: 0, width: (self.view.bounds.width * 9/10), height: (self.view.bounds.height * 9/10)))
    completionShadowView.center = self.view.center
    completionShadowView.layer.shadowColor = UIColor.black.cgColor
    completionShadowView.layer.shadowOffset = CGSize(width: 0, height: 10)
    completionShadowView.layer.shadowOpacity = 0.3
    completionShadowView.layer.shadowRadius = 15.0
    completionShadowView.tag = self.COMPLETION_VIEW_TAG
    return completionShadowView
  }
  
  func createCompletionGradientView(startColor: UIColor, endColor: UIColor) -> UIView {
    let completionView = GradientView(frame: CGRect(x: 0, y: 0, width: (self.view.bounds.width * 9/10), height: (self.view.bounds.height * 9/10)))
    completionView.startColor = startColor
    completionView.endColor = endColor
    completionView.layer.cornerRadius = 4
    completionView.clipsToBounds = true
    return completionView
  }
  
  func createCompletionViewLabel(completionView: UIView) -> UILabel {
    let completionLabel = UILabel(frame: CGRect(x: 0, y: 0, width: completionView.bounds.width*9/10, height: completionView.bounds.height))
    completionLabel.center.x = completionView.center.x
    completionLabel.center.y = completionView.bounds.height * 1/10
    completionLabel.font = UIFont.systemFont(ofSize: 24)
    completionLabel.text = "Who helped you out? Say thanks and pay it forward."
    completionLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
    completionLabel.numberOfLines = 2
    completionLabel.textColor = UIColor.white
    return completionLabel
  }
  
  func createUsersHelpedButton(completionView: UIView) -> UIButton {
    let usersHelpedButton = UIButton(frame: CGRect(x: 0, y: 0, width: completionView.bounds.width, height: 42))
    usersHelpedButton.titleLabel?.textAlignment = .center
    usersHelpedButton.setImage(UIImage(named: "smileyFace"), for: .normal)
    usersHelpedButton.isEnabled = false
    usersHelpedButton.setTitle("Thanks!", for: .normal)
    usersHelpedButton.tintColor = UIColor.white
    usersHelpedButton.center.x = completionView.center.x
    usersHelpedButton.center.y = completionView.bounds.height*8/10
    usersHelpedButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
    usersHelpedButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
    usersHelpedButton.tag = self.USERS_HELPED_BUTTON_TAG
    usersHelpedButton.alpha = 0.5
    usersHelpedButton.addTarget(self, action: #selector(self.handleUsersHelpedButtonPressed), for: .touchUpInside)
    return usersHelpedButton
  }
  
  func createUsersNoHelpButton(completionView: UIView) -> UIView {
    let usersNoHelpButton = UIButton(frame: CGRect(x: 0, y: 0, width: completionView.bounds.width, height: 42))
    usersNoHelpButton.setImage(UIImage(named: "frownFace"), for: .normal)
    usersNoHelpButton.titleLabel?.textAlignment = .center
    usersNoHelpButton.setTitle("No one helped me", for: .normal)
    usersNoHelpButton.tintColor = UIColor.white
    usersNoHelpButton.center.x = completionView.center.x
    usersNoHelpButton.center.y = completionView.bounds.height*9/10
    usersNoHelpButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
    usersNoHelpButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
    usersNoHelpButton.tag = self.NO_USERS_HELPED_BUTTON_TAG
    usersNoHelpButton.addTarget(self, action: #selector(self.handleNoOneHelpedButtonPressed), for: .touchUpInside)
    return usersNoHelpButton
  }
  
  func createMessageToThankUser(messageText: String, completionView: UIView, tagNumber: Int, userId: String) -> UIView {
    
    var buttonSize : CGFloat = completionView.bounds.width - 40;
    let messageWidth = messageText.widthOfString(usingFont: UIFont.systemFont(ofSize: 16)) + 40
    if messageWidth < buttonSize {
      buttonSize = messageWidth
    }
    
    let chatUserMessageButton = UIButton(frame: CGRect(x: 20, y: 0, width: buttonSize, height: 57))
    chatUserMessageButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
    chatUserMessageButton.tag = tagNumber
    chatUserMessageButton.setTitleColor(UIColor.black, for: .normal)
    chatUserMessageButton.center.y = completionView.bounds.height*3/10 + CGFloat(62 * tagNumber)
    //        chatUserMessageButton.center.x = self.view.center.x-20
    chatUserMessageButton.setTitle(messageText, for: .normal)
    chatUserMessageButton.backgroundColor = UIColor.white
    chatUserMessageButton.contentHorizontalAlignment = .left
    chatUserMessageButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 10, right: 5)
    chatUserMessageButton.cornerRadius = 5
    chatUserMessageButton.titleLabel?.lineBreakMode = NSLineBreakMode.byTruncatingMiddle
    chatUserMessageButton.titleLabel?.numberOfLines = 2
    chatUserMessageButton.alpha = 0.5
    
    // add user id to the button layer as data passed
    chatUserMessageButton.layer.setValue(userId, forKey: "userId")
    
    // TODO add target function for when the user clicks on a message button
    chatUserMessageButton.addTarget(self, action: #selector(self.handleCompletionViewChatUserMessageButtonPressed(sender:)), for: .touchUpInside)
    return chatUserMessageButton
  }
  
  // delete the task conversation
  func deleteTaskConversationForUser(userId: String) {
    self.channelsRef?.child(userId).removeValue()
  }
  
  // delete the current user's task
  func deleteTaskForUser(userId: String)  {
    self.tasksRef?.child(userId).removeValue()
  }
  
  // delete the task location
  func deleteTaskLocationForUser(userId: String) {
    self.tasksGeoFire?.removeKey(userId)
  }
  
  func deleteAndResetCurrentUserTask() {
    let timeStamp = Int(NSDate.timeIntervalSinceReferenceDate*1000)
    let currentUserKey = FIRAuth.auth()?.currentUser?.uid
    self.tasks[0] = Task(userId: currentUserKey!, taskDescription: "", latitude: (self.locationManager.location?.coordinate.latitude)!, longitude: (self.locationManager.location?.coordinate.longitude)!, completed: true, taskID: "\(timeStamp)",recentActivity: false, userMovedOutside: false)
    
    // delete the task
    self.tasksRef?.child(userTaskId!).removeValue()
    
    // delete the task location
    self.tasksGeoFire?.removeKey(userTaskId)
    
    // delete the task conversation
    self.channelsRef?.child(userTaskId!).removeValue()
    
    // reset boolean flags
    
    // flag for if the current task is saved
    self.currentUserTaskSaved = false
    
    // flag for if user swiped for new task
    self.newItemSwiped = false
    
    // reload carousel view for first card
    self.carouselView.reloadItem(at: 0, animated: true)
    
    // if the user is currently viewing their own card
    if self.carouselView.currentItemIndex == 0 {
      
      // transition to first card if there is another card
      if self.tasks.count > 1 {
        self.carouselView.scrollToItem(at: 1, animated: false)
        self.newItemSwiped = false
        self.carouselView.reloadItem(at: 0, animated: true)
        
        // or else show the the swiped card
      } else {
        self.newItemSwiped = true
        self.carouselView.reloadItem(at: 0, animated: true)
      }
      
    }
    
  }
  
  // action for when users complete task
  // and some users helped
  func handleUsersHelpedButtonPressed(sender: UIButton) {
    let completionView = self.view.viewWithTag(COMPLETION_VIEW_TAG)
    
    // fade out completion view before removing
    UIView.animate(withDuration: 1, animations: {
      completionView?.alpha = 0
    }) { _ in
      
      //scroll to first item if there is one
      if self.carouselView.itemView(at: 1) != nil {
        self.carouselView.scrollToItem(at: 1, animated: false)
      }
      
      let usersToThankCopy = self.usersToThank
      
      //update Complete task Status
      var currentUserTask = self.tasks[0] as! Task
      currentUserTask.completed = true;
      currentUserTask.completeType = Constants.STATUS_FOR_THANKED;
      currentUserTask.helpedBy = Array(usersToThankCopy.keys)
      
      self.removeTaskAfterComplete(currentUserTask)
      self.carouselView.removeItem(at: 0, animated: true)
      // thank the users that are in the thank users dictionary
      for userId in usersToThankCopy.keys {
        
        self.usersRef?.child(userId).observeSingleEvent(of: .value, with: { (snapshot) in
          
          // get the user dictionary
          let value = snapshot.value as? NSDictionary
          
          // get the user's current score
          let userScore = value?["score"] as? Int
          
          // get the user's current deviceToken
          let deviceToken = value?["deviceToken"] as? String
          
          // increment the score
          if userScore != nil {
            let newScore = userScore! + 1
            //add friend
            self.addFriend(userId)
            //update points
            self.UpdatePointsServer(1, userId)
            // send update to the user's score
            self.usersRef?.child(userId).child("score").setValue(newScore)
            print("new score set")
          }
          
          // send the user a notification that they were thanked
          if deviceToken != nil && deviceToken != self.currentUserId {
            PushNotificationManager.sendYouWereThankedNotification(deviceToken: deviceToken!, currentUserTask.taskDescription)
          }
          
        }, withCancel: { (error) in
          print(error.localizedDescription)
        })
        
      }
      
      completionView?.removeFromSuperview()
      // toggle carouselView to visible if hidden
      if self.carouselView.isHidden == true {
        self.carouselView.isHidden = false
      }
      //scroll to first item if there is one
      if self.carouselView.itemView(at: 1) != nil {
        self.carouselView.scrollToItem(at: 1, animated: false)
      }
    }
    
  }
  
  // action for when users complete task
  // and no users helped
  func handleNoOneHelpedButtonPressed(sender: UIButton) {
    let completionView = self.view.viewWithTag(COMPLETION_VIEW_TAG)
    
    
    // fade out completion view before removing
    UIView.animate(withDuration: 1, animations: {
      completionView?.alpha = 0
    }) { _ in
      
      // reset the users to thank dictionary
      self.usersToThank = [:]
      
      completionView?.removeFromSuperview()
      // toggle carouselView to visible if hidden
      if self.carouselView.isHidden == true {
        self.carouselView.isHidden = false
      }
      //scroll to first item if there is one
      if self.carouselView.itemView(at: 1) != nil {
        self.carouselView.scrollToItem(at: 1, animated: false)
      }
    }
    var currentUserTask = self.tasks[0] as! Task
    currentUserTask.completed = true;
    currentUserTask.completeType = Constants.STATUS_FOR_NOT_HELPED
    self.carouselView.removeItem(at: 0, animated: true)
    removeTaskAfterComplete(currentUserTask)
  }
  
  
  // action handler for chat messages
  func handleCompletionViewChatUserMessageButtonPressed(sender: UIButton) {
    
    // get the userId from the button
    let chatUserId = sender.layer.value(forKey: "userId") as? String
    
    // toggle the alpha of sender
    if sender.alpha == 0.5 {
      sender.alpha = 1
      
      // add the chatUserId into the users to thank array
      if chatUserId != nil {
        self.usersToThank[chatUserId!] = true
      }
      
      let usersHelpedButton = self.view.viewWithTag(USERS_HELPED_BUTTON_TAG) as! UIButton
      
      // if users helped button is faded
      if usersHelpedButton.alpha == 0.5 {
        // set to full opacity
        usersHelpedButton.alpha = 1
      }
      
      // if users helped button is disabled, enable it
      if usersHelpedButton.isEnabled == false {
        usersHelpedButton.isEnabled = true
      }
      
    } else {
      sender.alpha = 0.5
      
      // remove the chatUserId from the users to thank dictionary
      if chatUserId != nil {
        self.usersToThank.removeValue(forKey: chatUserId!)
      }
      
    }
    
    
  }
  
  //MARK:- new task created
  
  // action for done button item
  func createTaskForCurrentUser(sender: UIButton) {
    
    // TODO keyboard bug when user hits home button
    // create/update new task item for current user
    mTaskDescription = nil
    self.view.endEditing(true)
    showNotificationAlert()
    
    // get textview
    let currentUserTextView = self.view.viewWithTag(CURRENT_USER_TEXTVIEW_TAG) as! UITextView
    
    
    if let currentUserTask = self.tasks[0] {
      // taskdescription to be textView
      currentUserTask.latitude = (locationManager.location?.coordinate.latitude)!
      currentUserTask.longitude = (locationManager.location?.coordinate.longitude)!
      currentUserTask.completed = false
      currentUserTask.taskDescription = currentUserTextView.text
      currentUserTask.timeCreated = Date()
      currentUserTask.timeUpdated = Date()
      // update user task
      self.tasks[0] = currentUserTask
      //Current Task Created
      self.currentUserTaskSaved = true
      // save the user's current task
      currentUserTask.save(self)
      //Local Notification Implemented
      
      
      //Start monitoring Distance
      self.setUpGeofenceForTask(currentUserTask.latitude, currentUserTask.longitude)
      
      
      // TODO create users list for current user's conversation channel
      // and update the users list by appending the current user's id to the list
      let currentUserChannelId = FIRAuth.auth()?.currentUser?.uid
      // update the number of users in the channel
      // and update the current user to the users list
      self.channelsRef?.child(currentUserTask.taskID!).child("users").child(currentUserChannelId!).setValue(0)
      
      //self.channelsRef?.child(currentUserChannelId!).child("users_count").setValue(1)
      
      //add new annotation to the map for the current user's task
      let currentUserMapTaskAnnotation = CustomCurrentUserTaskAnnotation(currentCarouselIndex: 0)
      // set location for the annotation
      currentUserMapTaskAnnotation.coordinate = (locationManager.location?.coordinate)!
      self.mapView.addAnnotation(currentUserMapTaskAnnotation)
      
      // Send Push notification to nearby users.
      sendPushNotificationToNearbyUsers()
      
      // save current user task description to check if its
      // the same when timer is done
      //          startTimer(SECONDS_IN_HOUR)
      checkTaskTimeLeft()
      self.carouselView.reloadItem(at: 0, animated: true)
      
    }
    
    self.carouselView.reloadItem(at: 0, animated: true)
    
  }
  
  func sendPushNotificationToNearbyUsers() {
    if let currentUserTask = self.tasks[0] {
      for userId in self.nearbyUsers {
        self.usersRef?.child(userId).observeSingleEvent(of: .value, with: { (snapshot) in
          
          // get the user dictionary
          let value = snapshot.value as? NSDictionary
          
          // get the user's current deviceToken
          let deviceToken = value?["deviceToken"] as? String
          
          // send the user a notification to nearby users.
          if deviceToken != nil && userId != self.currentUserId {
            PushNotificationManager.sendNearbyTaskNotification(deviceToken: deviceToken!, taskID: currentUserTask.taskID!)
          }
          
        }, withCancel: { (error) in
          print(error.localizedDescription)
        })
      }
    }
    
  }
  
  // get rid of annotation when user deletes annotation
  func removeCurrentUserTaskAnnotation() {
    // loop through annotation in map view
    for annotation in self.mapView.annotations {
      // if one of them is a customCurrentUserTaskAnnotation
      if annotation is CustomCurrentUserTaskAnnotation {
        // get rid of it
        let annotationView = self.mapView.view(for: annotation)
        UIView.animate(withDuration: 0.5, animations: {
          annotationView?.alpha = 0.0
        }, completion: { (isCompleted) in
          self.mapView.removeAnnotation(annotation)
        })
        
      }
    }
  }
  
  // create custom notification
  func createLocalNotification(title: String, body: String?, time :Int){
    
    // create content
    let content = UNMutableNotificationContent()
    content.title = title
    if let contentBody = body {
      content.body = contentBody
    }
    var Interval = 0.5
    if title == "Hey! No activity is there from long time" {
      return
//      Interval = Double(time)
    }
    else {
      removeCurrentUserTaskAnnotation()
    }
    content.sound = UNNotificationSound.default()
    
    // create trigger
    let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: Interval, repeats: false)
    let request = UNNotificationRequest.init(identifier: "taskExpirationNotification", content: content, trigger: trigger)
    
    // schedule the notification
    let center = UNUserNotificationCenter.current()
    center.add(request, withCompletionHandler: { (error) in
      print(error ?? "Error")
    })
    
  }
  
  // action for close button item
  func discardCurrentUserTask(sender: UIButton) {
    mTaskDescription = nil
    let currentUserTextView = self.view.viewWithTag(self.CURRENT_USER_TEXTVIEW_TAG) as! UITextView
    currentUserTextView.resignFirstResponder()
    currentUserTextView.text = "What do you need help with?"
    currentUserTextView.alpha = 0.5
    
    sender.alpha = 0.5
    sender.isEnabled = false
    if let post_new_task_button = self.view.viewWithTag(self.POST_NEW_TASK_BUTTON_TAG) as? UIButton {
      post_new_task_button.alpha = 0.5
      post_new_task_button.isEnabled = false
    }
  }
  
  // action for chat to go to chat window
  func goToChat(sender: UIButton) {
    //        if locationManager.location?.coordinate.latitude == nil && locationManager.location?.coordinate.longitude == nil {
    //            showLocationAlert()
    //            return
    //        }
    // if the keyboard is out
    // remove it
    if self.view.frame.origin.y != 0 {
      UIApplication.shared.sendAction(#selector(UIApplication.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    let currentTask = self.tasks[self.carouselView.currentItemIndex]
    
    if currentTask?.taskDescription == ONBOARDING_TASK_1_DESCRIPTION ||  currentTask?.taskDescription == ONBOARDING_TASK_3_DESCRIPTION {
      return
    }
    
    self.performSegue(withIdentifier: "mainToChatVC", sender: nil)
  }
  
  // fired off when user begins dragging the carousel
  func carouselWillBeginDragging(_ carousel: iCarousel) {
    
  }
  
  // function called when carousel view scrolls
  func carouselDidScroll(_ carousel: iCarousel) {
    
    if self.view.frame.origin.y != 0 {
      UIApplication.shared.sendAction(#selector(UIApplication.resignFirstResponder), to: nil, from: nil, for: nil)
      self.view.frame.origin.y = 0
    }
    
    if(carousel.scrollOffset < 0.15 && self.newItemSwiped == false && canCreateNewtask == true) {
      self.newItemSwiped = true
      let defaults = UserDefaults.standard
      let boolForTask3 = defaults.bool(forKey: Constants.ONBOARDING_TASK3_VIEWED_KEY)
      if boolForTask3 == false {
        for (index, task) in self.tasks.enumerated() {
          if task?.taskDescription == ONBOARDING_TASK_3_DESCRIPTION {
            self.checkAndRemoveOnboardingTasks(carousel: carousel, cardIndex: index)
          }
          
        }
      }
      UIView.animate(withDuration: 1, animations: {
        carousel.reloadItem(at: 0, animated: true)
      })
      
    }
    
  }
  
  // called when animation is about to start
  func carouselWillBeginScrollingAnimation(_ carousel: iCarousel) {
    
    
  }
  
  func checkAndRemoveOnboardingTasks(carousel: iCarousel, cardIndex: Int) {
    let defaults = UserDefaults.standard
    
    if cardIndex < 0 || cardIndex >= self.tasks.count {
      return
    }
    
    // check if one of the onboarding tasks is at the current index
    let currentTask = self.tasks[cardIndex] as! Task
    
    if currentTask.taskDescription == self.ONBOARDING_TASK_1_DESCRIPTION {
      
      // set onboarding task 1 viewed to true
      defaults.set(true, forKey: Constants.ONBOARDING_TASK1_VIEWED_KEY)
      UpdatePointsServer(1, (FIRAuth.auth()?.currentUser?.uid)!)
      mTaskScore = mTaskScore + 1
      self.usersRef?.child((FIRAuth.auth()?.currentUser?.uid)!).child("score").setValue(mTaskScore)
      self.removeOnboardingFakeTask(carousel: carousel, cardIndex: cardIndex, userId: "101")
      
    }  else if currentTask.taskDescription == self.ONBOARDING_TASK_3_DESCRIPTION {
      
      // set onboarding task 3 viewed to true
      //            if defaults.bool(forKey: Constants.ONBOARDING_TASK2_VIEWED_KEY) == true {
      self.usersRef?.child(currentUserId!).child("isDemoTaskShown").setValue(true)
      UpdatePointsServer(1, (FIRAuth.auth()?.currentUser?.uid)!)
      mTaskScore = mTaskScore + 1
      self.usersRef?.child((FIRAuth.auth()?.currentUser?.uid)!).child("score").setValue(mTaskScore)
      defaults.set(true, forKey: Constants.ONBOARDING_TASK3_VIEWED_KEY)
      self.removeOnboardingFakeTask(carousel: carousel, cardIndex: cardIndex, userId: "103")
      //            }
      
    }
  }
  
  // remove the task if it is onboarding task
  func removeOnboardingFakeTask(carousel: iCarousel, cardIndex: Int, userId: String) {
    // delete that task and card and map icon
    self.tasks.remove(at: cardIndex)
    self.carouselView.removeItem(at: cardIndex, animated: true)
    // carouselView.reloadData()
    print("Deleted Id \(userId)")
    let when = DispatchTime.now()  // change 2 to desired number of seconds
    DispatchQueue.main.asyncAfter(deadline: when) {
      
      for annotation in self.mapView.annotations {
        
        if annotation is CustomFocusTaskMapAnnotation  {
          let customAnnotation = annotation as! CustomFocusTaskMapAnnotation
          print("customAnnotation \(String(describing: customAnnotation.currentCarouselIndex))")
          if customAnnotation.taskUserId == userId {
            // if its equal to the current index remove it
            print("Deleted Id \(userId)")
            self.clusterManager.remove(customAnnotation)
            self.mapView.removeAnnotation(customAnnotation)
              self.clusterManager.reload(self.mapView, visibleMapRect: self.mapView.visibleMapRect)
          }
        }
        
        if annotation is CustomTaskMapAnnotation  {
          let customAnnotation = annotation as! CustomTaskMapAnnotation
          print("customAnnotation \(String(describing: customAnnotation.currentCarouselIndex))")
          if customAnnotation.taskUserId == userId {
            // if its equal to the current index remove it
            print("Deleted Id \(userId)")
            self.clusterManager.remove(customAnnotation)
            self.mapView.removeAnnotation(customAnnotation)
              self.clusterManager.reload(self.mapView, visibleMapRect: self.mapView.visibleMapRect)
          }
        }
        self.clusterManager.reload(self.mapView, visibleMapRect: self.mapView.visibleMapRect)
      }
      // update the rest of the annotations
      self.updateMapAnnotationCardIndexes()
    }
  }
  
  /// function to test map annotations error
  func testMapAnnotations() {
    // print out all the annotations and their indexes
    print("new line ------")
    for annotation in self.mapView.annotations {
      if annotation is CustomFocusTaskMapAnnotation {
        let customAnnotation = annotation as! CustomFocusTaskMapAnnotation
        print("customFocusTaskMapAnnotation \(customAnnotation.currentCarouselIndex!) \(customAnnotation.taskUserId!)")
      } else if annotation is CustomTaskMapAnnotation {
        let customAnnotation = annotation as! CustomTaskMapAnnotation
        print("customTaskMapAnnotation \(customAnnotation.currentCarouselIndex!) \(customAnnotation.taskUserId!)")
      } else if annotation is CustomCurrentUserTaskAnnotation {
        let customAnnotation = annotation as! CustomCurrentUserTaskAnnotation
        print("customCurrentUserTaskAnnotation \(customAnnotation.currentCarouselIndex!)")
        
      }
      
      
    }
    // print out the current carousel index
    print(self.carouselView.currentItemIndex)
    //print out the tasks in tasks array and their associated index and user id
    for (index, task) in self.tasks.enumerated() {
      print("Item \(index): \(task?.userId)")
    }
    
  }
  
  // update map annotations after the tasks/indexes are changed
  func updateMapAnnotationCardIndexes() {
    // loop through each annotation and check if they are task or focus task annotations
    for annotation in self.mapView.annotations {
      
      if annotation is CustomTaskMapAnnotation {
        
        // loops through the tasks array and find the corresponding task
        let customAnnotation = annotation as! CustomTaskMapAnnotation
        
        for (index, task) in self.tasks.enumerated() {
          
          // check if the task has the same id as the annotation
          if let taskUserId = customAnnotation.taskUserId {
            if taskUserId == task?.taskID {
              
              // if they match update the annotation with the correct index
              customAnnotation.currentCarouselIndex = index
              print("index set \(index)")
              break
            }
          }
          
        }
        
        
      } else if annotation is CustomFocusTaskMapAnnotation {
        
        // loops through the tasks array and find the corresponding task
        let customAnnotation = annotation as! CustomFocusTaskMapAnnotation
        
        for (index, task) in self.tasks.enumerated() {
          
          // check if the task has the same id as the annotation
          if let taskUserId = customAnnotation.taskUserId{
            if taskUserId == task?.taskID {
              
              // if they match update the annotation with the correct index
              customAnnotation.currentCarouselIndex = index
              break
            }
          }
          
        }
        
        
      }
      
    }
    
    
  }
  
  
  // change the center of the map based on the currently selected task
  func carouselCurrentItemIndexDidChange(_ carousel: iCarousel) {
    
    // test for bugs for map annotations
    testMapAnnotations()
    
    // use the last item index (it gets updated at the end of the method)
    // and check if the last card is an onboarding task
    let defaults = UserDefaults.standard
    let boolForTask1 = defaults.bool(forKey: Constants.ONBOARDING_TASK1_VIEWED_KEY)
    
    let when = DispatchTime.now() + 0.4  // change 2 to desired number of seconds
    DispatchQueue.main.asyncAfter(deadline: when) {
      if let lastCardIndex = self.lastCardIndex, lastCardIndex != carousel.currentItemIndex, boolForTask1 == false {
        if let swipedTask:Task = self.tasks[self.lastCardIndex!] {
          if swipedTask.taskDescription == self.ONBOARDING_TASK_1_DESCRIPTION && (self.carouselView.currentItemIndex == 2 || self.carouselView.currentItemIndex == 3 ) {
            self.checkAndRemoveOnboardingTasks(carousel: carousel, cardIndex: self.lastCardIndex!)
              self.carouselView.scrollToItem(at: self.lastCardIndex!, animated: false)
            return
            
          }
        }
      }
      if self.carouselView.currentItemIndex > 0 && self.carouselView.currentItemIndex < self.tasks.count {
        if let currentTask = self.tasks[self.carouselView.currentItemIndex] {
          if currentTask.completed == true {
            let taskCordinates = CLLocationCoordinate2D.init(latitude: currentTask.latitude, longitude: currentTask.longitude)
            self.expiredAnnotation.coordinate = taskCordinates
            let annotationView = self.mapView.view(for: self.expiredAnnotation)
            self.mapView.addAnnotation(self.expiredAnnotation)
//            annotationView?.layer.zPosition = CGFloat(self.ANNOTATION_TOP_INDEX)
            annotationView?.superview?.bringSubview(toFront: annotationView!)
            
          } else {
            self.mapView.removeAnnotation(self.expiredAnnotation)
          }
          
        }
        
      }
      
      
      self.updateMapAnnotationCardIndexes()
      
      // loop through the annotations currently on the map
      let annotations = self.mapView.annotations
      for annotation in annotations {
        
        // check if the annotation is a custom current user task annotation
        if annotation is CustomCurrentUserTaskAnnotation  {
          // remove and add it back on
          
          // reload annotation
          let annotationClone = annotation
          self.mapView.removeAnnotation(annotation)
          self.mapView.addAnnotation(annotationClone)
          
          
        }
        
        // check for the annotation for current card
        if annotation is CustomTaskMapAnnotation  {
          let mapTaskAnnotation = annotation as! CustomTaskMapAnnotation
          print(self.carouselView.currentItemIndex);
          print(mapTaskAnnotation.currentCarouselIndex);
          if mapTaskAnnotation.currentCarouselIndex == self.carouselView.currentItemIndex {
            // once the right annotation is found
            
            // add the annotation with a different class
            // create new focus annotation class for the current map icon
            let index = self.carouselView.currentItemIndex
            
            // get user id for the task
            let taskUserId = (mapTaskAnnotation.taskUserId != nil) ? mapTaskAnnotation.taskUserId! : ""
            
            let focusAnnotation = CustomFocusTaskMapAnnotation(currentCarouselIndex: index, taskUserId: taskUserId)
            focusAnnotation.coordinate = mapTaskAnnotation.coordinate
            focusAnnotation.style = .color(#colorLiteral(red: 0, green: 0.5901804566, blue: 0.758269012, alpha: 1), radius: 30)//.image(#imageLiteral(resourceName: "newNotificaitonIcon"))
            self.clusterManager.remove(mapTaskAnnotation)
            self.mapView.removeAnnotation(mapTaskAnnotation)
//            self.clusterManager.add(focusAnnotation)
              self.mapView.addAnnotation(focusAnnotation)
            self.mapView.selectAnnotation(focusAnnotation, animated: false)
          }
        }
        
        if annotation is CustomFocusTaskMapAnnotation {
          let customFocusTaskAnnotation = annotation as! CustomFocusTaskMapAnnotation
          // get the current index
          let index = self.carouselView.currentItemIndex
          
          // get the user id from the annotation
          let taskUserId = (customFocusTaskAnnotation.taskUserId != nil) ? customFocusTaskAnnotation.taskUserId! : ""
          
          // add regular task icon
          let taskAnnoation = CustomTaskMapAnnotation(currentCarouselIndex: index, taskUserId: taskUserId)
          taskAnnoation.coordinate = customFocusTaskAnnotation.coordinate
          //
          //                    // remove focus task icon
          self.clusterManager.remove(customFocusTaskAnnotation)
          self.mapView.removeAnnotation(customFocusTaskAnnotation)
          taskAnnoation.style = .color(#colorLiteral(red: 0, green: 0.5901804566, blue: 0.758269012, alpha: 1), radius: 30)
//          let annotationView = self.mapView.view(for: taskAnnoation)
//          annotationView?.layer.zPosition = CGFloat(self.STANDARD_MAP_TASK_ANNOTATION_Z_INDEX)
          self.clusterManager.add(taskAnnoation)
         self.clusterManager.reload(self.mapView, visibleMapRect: self.mapView.visibleMapRect)
        }
      }
    
      let taskIndex = self.carouselView.currentItemIndex
      
      if taskIndex >= 0 && taskIndex < self.tasks.count {
        
        if let task = self.tasks[taskIndex] {
          if task.taskDescription != "" {
            self.updateViewsCount(task.taskID!)
          }
          let taskLat = task.latitude
          let taskLong = task.longitude
          let taskCoordinate = CLLocationCoordinate2D(latitude: taskLat, longitude: taskLong)
          self.mapView.setCenter(taskCoordinate, animated: true)
          print("map center changed to lat:\(task.latitude) long:\(task.longitude)")
        }
      }
      
      // update the last carousel card index
      //self.lastCardIndex = carousel.currentItemIndex
    }
    
    
    
  }
  func carousel(_ carousel: iCarousel, valueFor option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
    if option == iCarouselOption.spacing {
      return value * 1.03
    }
    
    return value
  }
  
  func numberOfItems(in carousel: iCarousel) -> Int {
    return tasks.count
  }
  
  func carouselScroll(_ pTask:String) {
    for (index, task) in self.tasks.enumerated() {
      if pTask == task?.taskID {
        self.carouselView.scrollToItem(at: index, animated: true)
      }
    }
  }
  
}

// MARK: - MainViewController (Notifications)

extension MainViewController {
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    
    if self.view.frame.origin.y != 0 {
      UIApplication.shared.sendAction(#selector(UIApplication.resignFirstResponder), to: nil, from: nil, for: nil)
    }
  }
}

