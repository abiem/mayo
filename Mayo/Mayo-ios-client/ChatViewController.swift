//
//  ChatViewController.swift
//  Mayo-ios-client
//
//  Created by abiem  on 4/12/17.
//  Copyright © 2017 abiem. All rights reserved.
//

import UIKit
import Firebase
import JSQMessagesViewController
import Alamofire
import IQKeyboardManagerSwift


class ChatViewController: JSQMessagesViewController {
    var isFakeTask = false
    var isOwner = false
    var channelRef: FIRDatabaseReference?
    var taskRef: FIRDatabaseReference?
    var taskHandler : FIRDatabaseHandle?
    var channelId: String?
    var channelTopic: String?
    var messages = [Message]()
    var currentUserColorIndex: Int? = nil
    var isParticipated = false;
    var isCompleted = false;
    var mDeclinedNotification = false
  
    @IBOutlet weak var viewQuestCompleted: UIView!
    
    
    private lazy var messageRef: FIRDatabaseReference = self.channelRef!.child("messages")
    private var newMessageRefHandle: FIRDatabaseHandle?

    override func viewDidLoad() {
        super.viewDidLoad()
        taskRef = FIRDatabase.database().reference().child("tasks").child(channelId!)
        checkNotificationPermission()
        self.topContentAdditionalInset = 0.0
        
        // disable swipe to navigate
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        // check if the current user id and channel id match
        // if they match, set gray color for the current user(index 0)
        checkColorIndexForCurrentUserIfOwner()
        
        // No avatars
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        // turns off attachments button
        self.inputToolbar.contentView.leftBarButtonItem = nil
        self.inputToolbar.contentView.textView.autocapitalizationType = .sentences
        self.inputToolbar.contentView.textView.autocorrectionType = .yes
        self.inputToolbar.contentView.textView.spellCheckingType = .yes
        
        if #available(iOS 11.0, *) {
            self.inputToolbar.contentView.textView.smartQuotesType = .yes
            self.inputToolbar.contentView.textView.smartDashesType = .yes
            self.inputToolbar.contentView.textView.smartInsertDeleteType = .yes
        }

        
        // set senderid as current user id
        self.senderId = FIRAuth.auth()?.currentUser?.uid
        self.senderDisplayName = ""
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // listen for new messages
        IQKeyboardManager.sharedManager().enable = false
        observeMessages()
        if isCompleted == false {
            checkTaskCompletion()
        } else {
            let parentSize = self.view.frame.size
            viewQuestCompleted.frame = CGRect(x:0, y: parentSize.height-44, width:parentSize.width, height:44)
            self.inputToolbar.isHidden = true
            self.view.addSubview(viewQuestCompleted)
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        // remove observer for messages
        IQKeyboardManager.sharedManager().enable = true
        messageRef.removeObserver(withHandle: newMessageRefHandle!)
        if isCompleted == false {
            taskRef?.child("completed").removeObserver(withHandle: taskHandler!)
        }
    }
    
    private func checkColorIndexForCurrentUserIfOwner() {
        // set the color index to 0 if the current channel was created
        // by the current user
        if isFakeTask == true {
            self.currentUserColorIndex = 1
        }
        else {
            taskRef?.child("createdby").observe(.value, with: { (snapshot) -> Void in
                if let user = snapshot.value as? String {
                    if user == FIRAuth.auth()?.currentUser?.uid {
                        // if the user id and the channel id match
                        // set the current color index to 0
                        self.currentUserColorIndex = 0
                        self.isOwner = true
                        print("current user color index was set")
                    }
                }
            })
        }
            
        
        
    }
    
    // create new message
    private func addMessage(withId id: String, name: String, text: String, colorIndex: Int) {
        let message = Message(senderId: id, senderDisplayName: name, text: text, colorIndex: colorIndex)
        //JSQMessage(senderId: id, displayName: name, text: text) {
        messages.append(message)
    }
    
    override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
        // If the text is not empty, the user is typing
        print(textView.text != "")
    }
    override func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if #available(iOS 11.0, *){
            self.topContentAdditionalInset = -64
        }
      
      if CLLocationManager.locationServicesEnabled()
      {
        let status: CLAuthorizationStatus = CLLocationManager.authorizationStatus()
        if status == .authorizedAlways || status == .authorizedWhenInUse {
          return true
        }
      
      }
      showLocationAlert()
        return false
    }
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        // check if current user color index is set
        if self.currentUserColorIndex == nil {
            // check if current user is in the conversation
            self.channelRef?.child("users").observeSingleEvent(of: .value, with: { (snapshot) in
                
                // boolean flag to check if current user is in the conversation already
                var currentUserIsInConversation:Bool = false
                let usersValue = snapshot.value as? NSDictionary ?? [:]
                for (userId, colorIndex) in usersValue {
                   // if a key matches the current user's uid
                    if userId as? String == FIRAuth.auth()?.currentUser?.uid {
                        // set the color index to the value
                        self.currentUserColorIndex = colorIndex as? Int
                        // break out of the loop
                        currentUserIsInConversation = true
                        break
                    }
                    
                }
                // if the user is not in the conversation
                if currentUserIsInConversation == false {
                    
                    // add the user to the conversation and increment users counter
                    let usersCountAndNewColorIndex = usersValue.allKeys.count
                    
                    //save the index
                    self.channelRef?.child("users").child((FIRAuth.auth()?.currentUser?.uid)!).setValue(usersCountAndNewColorIndex)
                    self.currentUserColorIndex = usersCountAndNewColorIndex
                    self.saveMessageAndUpdate(text: text, senderId: senderId, senderDisplayName: senderDisplayName, date: date)
                    
                    // update the current task with emoji star U+2B50
                    
                } else {
                    
                    // user is already in the conversation and is found
                    // rest of update
                    self.saveMessageAndUpdate(text: text, senderId: senderId, senderDisplayName: senderDisplayName, date: date)
                }
            
            }, withCancel: { (error) in
                print(error)
            })
            
            
        } else {
            self.saveMessageAndUpdate(text: text, senderId: senderId, senderDisplayName: senderDisplayName, date: date)
        }
        if !isParticipated {
            setTaskParticipated()
        }
        
    }
    
    // TODO update the task with star emoji for description
    func updateTaskDescriptionWithStarEmoji() {
        let viewControllersCount = self.navigationController?.viewControllers.count
        if let mainViewController = self.navigationController?.viewControllers[viewControllersCount! -  2] as? MainViewController {
        }
        
    }
    
    func saveMessageAndUpdate(text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        // check if the sender is the same as the channel id
        // which means that the user who is sending is part of their own
        // if the ids match, then add the screaming face emoticon
        var textToSend = text
        let dateFormatter = DateStringFormatterHelper()
        let dateCreated = dateFormatter.convertDateToString(date: Date())
      
      //Show Notification Alert
      DispatchQueue.main.async {
        self.showNotificationAlert()
      }

      
        
        if isFakeTask {
            let defaults = UserDefaults.standard
            defaults.set(true, forKey: "onboardingTask2Viewed")
            self.addMessage(withId: self.senderId, name: "", text: text, colorIndex: self.currentUserColorIndex!)
            self.finishSendingMessage()
            receiveFakeMessage()
        }
        else {
            if isOwner   {
                let screamingFaceEmoji = "\u{1F631} " //U+1F631
                textToSend = screamingFaceEmoji + text!
                
            } else  {
                FIRDatabase.database().reference().child("tasks").child(channelId!).child("recentActivity").setValue(true)
            }
            FIRDatabase.database().reference().child("tasks").child(channelId!).child("timeUpdated").setValue(dateCreated)
            let itemRef = messageRef.childByAutoId()
            let messageItem = [
                "senderId": senderId!,
                "senderName": senderDisplayName!,
                "text": textToSend!,
                "colorIndex": "\(self.currentUserColorIndex!)",
                "dateCreated": dateCreated
            ]
            
            itemRef.setValue(messageItem)
            
            JSQSystemSoundPlayer.jsq_playMessageSentSound()
            if let channelId = self.channelId {
                
                self.sendNotificationToTopic(channelId: channelId)
                
                FIRMessaging.messaging().subscribe(toTopic: "/topics/\(channelId)")
                
            }
        }
        // get the current user's color index if the user is already in the conversation
        
        // if the user is not currently in the conversation
        // add the user to the conversation and create an index for them
        
       
       
        //self.channelRef?.child("updatedAt").setValue(dateCreated)
    
        finishSendingMessage()
    }
    
    // TODO: send notification to the topic for specific channel id
    func sendNotificationToTopic(channelId: String) {
        
        // TODO: add application/json and add authorization key
        var channelTopicMessage = ""
        if let channelTopic = self.channelTopic {
            channelTopicMessage = channelTopic
        }
        let currentUserId = FIRAuth.auth()?.currentUser?.uid
       let ref  = FIRDatabase.database().reference()
        ref.child("channels").child(channelId).child("users").observeSingleEvent(of: .value, with: { (snapshot) in
            let users  = snapshot.value as! [String:Any]
            for user in Array(users.keys) {
                if user != currentUserId {
                    ref.child("users").child(user).child("deviceToken").observeSingleEvent(of: .value, with: { (snapshot) in
                        if let token = snapshot.value as? String {
                            PushNotificationManager.sendNotificationToDeviceForMessage(device: token , channelId: channelId, topic: channelTopicMessage, currentUserId: currentUserId!)
                        }
                    })
                }
            }

        })
    }
    
    //reload messages.
    public func reloadChat() {
        self.observeMessages()
    }
    
    // listen for new messags
    private func observeMessages() {
        messageRef = channelRef!.child("messages")
        let messageQuery = messageRef.queryLimited(toLast:25)
        
        //  We can use the observe method to listen for new
        // messages being written to the Firebase DB
        newMessageRefHandle = messageQuery.observe(.childAdded, with: { (snapshot) -> Void in
            let messageData = snapshot.value as! Dictionary<String, String>
            if let id = messageData["senderId"] as String!, let name = messageData["senderName"] as String!, let text = messageData["text"] as String!, text.count > 0, let colorIndexAsInt = Int(messageData["colorIndex"]!) {
                self.addMessage(withId: id, name: name, text: text, colorIndex: colorIndexAsInt)
                self.finishReceivingMessage()
            } else {
                print("Error! Could not decode message data")
            }
        })
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        cell.textView?.textColor = UIColor.white
        return cell
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        
        if message.senderId() == senderId {
            // TODO get the correct index for the sender
            // pass in the correct index to get the correct color
            let messageColorIndex = message.colorIndex != nil ? message.colorIndex! : 0
            let outgoingBubbleImage = setupOutgoingBubble(colorIndex: messageColorIndex)
            return outgoingBubbleImage
        } else {
            let messageColorIndex = message.colorIndex != nil ? message.colorIndex! : 0
            let incomingBubbleImage = setupIncomingBubble(colorIndex: messageColorIndex)
            return incomingBubbleImage
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }

   
    private func setupOutgoingBubble(colorIndex: Int) -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        let indexAfterModulo = colorIndex % Constants.chatBubbleColors.count
        return bubbleImageFactory!.outgoingMessagesBubbleImage(with: UIColor.hexStringToUIColor(hex: Constants.chatBubbleColors[indexAfterModulo]))
    }
    
    // TODO: change the color of the chat user
    // based on who it is
    // annonymous colors
    private func setupIncomingBubble(colorIndex: Int) -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        let indexAfterModulo = colorIndex % Constants.chatBubbleColors.count
        return bubbleImageFactory!.incomingMessagesBubbleImage(with: UIColor.hexStringToUIColor(hex: Constants.chatBubbleColors[indexAfterModulo]))//UIColor.jsq_messageBubbleLightGray())
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
//    MARK:- Custom Methods
    
    //Update task participate count at user node
    func setTaskParticipated()  {
       
        let userId = FIRAuth.auth()?.currentUser?.uid;
        let usersRef =  FIRDatabase.database().reference().child("users")
            usersRef.child(userId!).child("taskParticipated").observeSingleEvent(of: .value, with: { (snapshot) in
                
                if let arrUsersParticipated = snapshot.value as? [String : Any] {
                        if var tasks = arrUsersParticipated["tasks"] as? [String] {
                            if !tasks.contains(self.channelId!) {
                                tasks.append(self.channelId!)
                            let tasksParticipateUpdate =  ["tasks" : tasks, "count":tasks.count] as [String : Any];
                                self.updateTaskAtServer(userId!, tasksParticipateUpdate, usersRef)
                            }
                    }
                        else {
                            let tasksParticipateUpdate =  ["tasks" : [self.channelId], "count":1] as [String : Any];
                            self.updateTaskAtServer(userId!, tasksParticipateUpdate, usersRef)
                    }
                }
                else {
                    let tasksParticipateUpdate =  ["tasks" : [self.channelId], "count":1] as [String : Any];
                    self.updateTaskAtServer(userId!, tasksParticipateUpdate, usersRef)
                }
        })
        isParticipated = true;
        
    }
    
    //Update task Participate at Server
    func updateTaskAtServer(_ userID:String, _ taskDetail:[String:Any], _ ref: FIRDatabaseReference)  {
        ref.child(userID).child("taskParticipated").setValue(taskDetail)
    }

    func receiveFakeMessage() {
        
      let when = DispatchTime.now() // change 2 to desired number of seconds
        DispatchQueue.main.asyncAfter(deadline: when) {
            let id = "Robot"
            let name = ""
            let text = "\u{1F631} Woohoo thank you!"
            let colorIndexAsInt = 0
            self.addMessage(withId: id, name: name, text: text, colorIndex: colorIndexAsInt)
            self.finishReceivingMessage()
        }
    }
    
    func checkTaskCompletion() {
        taskHandler = taskRef?.child("completed").observe(.value, with: { (snapshot) -> Void in
             if let isCompleted = snapshot.value as? Bool {
                if isCompleted ==  true {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        })
    }
  
  func showLocationAlert() {
    CMAlertController.sharedInstance.showAlert(nil, Constants.sLOCATION_ERROR, ["Not now", "Settings"]) { (sender) in
      if let button = sender {
        if button.tag == 1 {
          // for Move to Settings
          UIApplication.shared.open(URL(string:UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
        }
      }
    }
    
  }
  
  func checkNotificationPermission() {
    checkStatusOfNotification { (status) in
      if status == .notDetermined {
        self.mDeclinedNotification = false
      } else {
        self.mDeclinedNotification = true
      }
    }
  }
  
  func showNotificationAlert() {
    if mDeclinedNotification == false {
        self.view.endEditing(true)
          CMAlertController.sharedInstance.showAlert(nil, Constants.sNOTIFICATION_ERROR, ["Not now", "Sure"]) { (sender) in
            self.mDeclinedNotification = true
            if let button = sender {
              if button.tag == 1 {
                requestForNotification()
              }
            }
            if self.isFakeTask {
              let when = DispatchTime.now() + 3 // change 2 to desired number of seconds
              DispatchQueue.main.asyncAfter(deadline: when ) {
                self.navigationController?.popViewController(animated: true)
              }
              
            }
            
          }
    }
  }
    
}
