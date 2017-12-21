//
//  CMAlertController.swift
//  Mayo-ios-client
//
//  Created by Lakshmi Kodali on 08/12/17.
//  Copyright © 2017 Weijie. All rights reserved.
//

// Show Custom Alert on Top View Controller

import UIKit

// Constants to customise Alert
let sALERT_WIDTH = 300 //Int(UIScreen.main.bounds.size.width * 0.8)
let sALERT_COLOR = #colorLiteral(red: 0, green: 0.7709392309, blue: 0.8868473172, alpha: 1)
let sALERT_BACKGROUND_COLOR = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.3)
let sALERT_VIEW_BORDER_WIDTH = 2
let sALERT_VIEW_CORNER_RADIUS = 5
let sALERT_BUTTON_HEIGHT = 40
let sALERT_BUTTON_Y_PADDING = 6
let sALERT_TITLE_SIZE = 17
let sALERT_LABEL_HEIGHT = 70
let sALERT_IMAGE_HEIGHT = 50
let sALERT_MARGIN_FROM_LEFT = 15
let sALERT_MARGIN_FROM_TOP = 15
let sALERT_LABEL_FONT_SIZE = 14
let sALERT_SHADOW_WIDTH = 0
let sALERT_SHADOW_HEIGHT = 20
let sALERT_SHADOW_OPACITY = 0.45
let sALERT_SHADOW_RADIUS = 30
let sALERT_DIAGONAL_START = "FFFFFF"
let sALERT_DIAGONAL_END = "EAFCFF"
let sALERT_TITLE_FONT_NAME  = "HelveticaNeue-Bold"
/**
 Callback for button Action
 @response UIButton optional
 */
typealias completionHandler = ((UIButton?) -> ())?

class CMAlertController: NSObject {
    
    /**
     Background Blur view
     */
   private var mAlertBackgroundView = UIView()
   private var callBack : completionHandler?
    
    /**
        Create/Get CMAlertController Single instance
     */
    class var sharedInstance: CMAlertController {
        struct Static {
            static let instance = CMAlertController()
        }
        return Static.instance
    }
    
    /**
     Show Alert on Top View Controller
     @param pTitle Title for Custom Alert
     @param pSubtitle Subtitle for Custom Alert
     @param pButtonArray Array of buttons titles
     @return selected button
     */
    func showAlert(_ pTitle: String?, _ pSubtitle: String?, _ pButtonArray:[String], _ pHandler: completionHandler?) {
        callBack = nil
        if let callbackHandler = pHandler {
            callBack = callbackHandler
        }
      createAlertView(pTitle, nil, pSubtitle, pButtonArray)
    }
  
  /**
   Show Alert on Top View Controller
   @param pTitle Title for Custom Alert
   @param pSubtitle Subtitle for Custom Alert
   @param pButtonArray Array of buttons titles
   @return selected button
   */
  func showImageCustomisedAlert(_ pTitle: String?,_ pImage: UIImage? , _ pSubtitle: String?, _ pButtonArray:[String], _ pHandler: completionHandler?) {
    callBack = nil
    if let callbackHandler = pHandler {
      callBack = callbackHandler
    }
    createAlertView(pTitle, pImage, pSubtitle, pButtonArray)
  }
  
  
  
    /**
     Remove Alert From Screen
     */
    func dismissController() {
        callBack = nil
        mAlertBackgroundView.subviews.forEach { $0.removeFromSuperview() }
        mAlertBackgroundView.removeFromSuperview()
    }
    
    /**
     Create Label and Buttons
     @param pTitle Title for Custom Alert
     @param pSubtitle Subtitle for Custom Alert
     @param pButtonArray Array of buttons titles
     */
  private func createAlertView(_ pTitle: String?,_ pSubImage: UIImage? , _ pSubtitle: String?, _ pButtonArray:[String]) {
    if let parentView = topController()?.view {
        if !parentView.subviews.contains(mAlertBackgroundView) {
            parentView.addSubview(mAlertBackgroundView)
            setToSuperView(mAlertBackgroundView, pParentView: parentView)
            mAlertBackgroundView.backgroundColor = sALERT_BACKGROUND_COLOR
            
            let alertView = DiagonalGradientView()
            mAlertBackgroundView.addSubview(alertView)
//            alertView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
          alertView.startColor = UIColor.hexStringToUIColor(hex: sALERT_DIAGONAL_START)
          alertView.endColor = UIColor.hexStringToUIColor(hex: sALERT_DIAGONAL_END)
            alertView.layer.cornerRadius = 0
          
          //Add Shadow
          alertView.layer.shadowColor = UIColor.black.cgColor
          alertView.layer.shadowOffset = CGSize(width: sALERT_SHADOW_WIDTH, height: sALERT_SHADOW_HEIGHT)
          alertView.layer.shadowOpacity = Float(sALERT_SHADOW_OPACITY)
          alertView.layer.shadowRadius = CGFloat(sALERT_SHADOW_RADIUS)
          
            var bottomValue:CGFloat = CGFloat(sALERT_MARGIN_FROM_TOP)
          
            if let title = pTitle  {
                let label = createLabel(title, bottomValue)
                label.textAlignment = .center
              label.font = UIFont(name:sALERT_TITLE_FONT_NAME, size: CGFloat(sALERT_TITLE_SIZE))
              label.sizeToFit()
                alertView.addSubview(label)
                bottomValue = label.frame.size.height  + label.frame.origin.y + CGFloat(sALERT_MARGIN_FROM_TOP)
            }
          
            if let image = pSubImage {
              let imageView = createImage(image, bottomValue)
              imageView.image = image
              alertView.addSubview(imageView)
              bottomValue = imageView.frame.size.height  + imageView.frame.origin.y + CGFloat(sALERT_MARGIN_FROM_TOP)
          }
          
            if let title = pSubtitle  {
                let label = createLabel(title, bottomValue)
                label.textAlignment = .justified
              label.font = label.font.withSize(CGFloat(sALERT_LABEL_FONT_SIZE))
              label.sizeToFit()
                alertView.addSubview(label)
                bottomValue = label.frame.size.height + label.frame.origin.y + CGFloat(sALERT_MARGIN_FROM_TOP)
            }
            
            for (index, buttonTitle) in pButtonArray.enumerated() {
                let button = createButton(buttonTitle, bottomValue, pButtonNumber:pButtonArray.count , pIndex: index)
                alertView.addSubview(button)
                bottomValue = button.frame.size.height + button.frame.origin.y + CGFloat(sALERT_MARGIN_FROM_TOP)
                
            }
            
            alertView.frame = CGRect(x:0, y:0 , width:Int(sALERT_WIDTH), height:Int(bottomValue))
            alertView.center.x = parentView.center.x
            alertView.center.y = parentView.center.y 
            
            }
        }
    
    }
    
    /**
     Create Label
     @param pTitle Title for Custom Alert
     @param pYAxis Y positions of label
     @return customised label
     */
   private func createLabel(_ pTitle: String, _ pYAxis :CGFloat) -> UILabel{
    let placeHolderWidth = sALERT_MARGIN_FROM_LEFT * 2
        let label = UILabel.init(frame: CGRect(x:sALERT_MARGIN_FROM_LEFT, y:Int(pYAxis), width:sALERT_WIDTH - placeHolderWidth, height:sALERT_LABEL_HEIGHT ))
        label.text = pTitle
        label.textColor = sALERT_COLOR
        label.numberOfLines = 0
    
        return label
    }
  
  /**
   Create ImageView
   @param pImage Image for Custom Alert
   @param pYAxis Y positions of Image
   @return customised UIImageView
   */
  private func createImage(_ pImage: UIImage, _ pYAxis :CGFloat) -> UIImageView {
    let placeHolderWidth = sALERT_MARGIN_FROM_LEFT * 2
    let imageView = UIImageView.init(frame: CGRect(x:sALERT_MARGIN_FROM_LEFT, y:Int(pYAxis), width:sALERT_WIDTH - placeHolderWidth, height:sALERT_LABEL_HEIGHT ))
   imageView.contentMode = .scaleAspectFit
    return imageView
  }
    
    /**
     Create button
     @param pTitle Title for button
     @param pYAxis Y positions of label
     @param pButtonNumber Total number of buttons
     @param pIndex Current button index
     @return customised label
     */
   private func createButton(_ pTitle: String, _ pYAxis :CGFloat , pButtonNumber:Int, pIndex:Int) -> UIButton {
        var width = 0
        var xAxis = sALERT_MARGIN_FROM_LEFT
        var yAxis = pYAxis + CGFloat(sALERT_BUTTON_Y_PADDING)
        if pButtonNumber == 2 {
          width = (sALERT_WIDTH - Int(sALERT_MARGIN_FROM_LEFT*3))/2
            xAxis = pIndex % 2 != 0 ? width + (sALERT_MARGIN_FROM_LEFT*2)  : sALERT_MARGIN_FROM_LEFT
            yAxis = pIndex % 2 != 0 ? yAxis - CGFloat(sALERT_BUTTON_HEIGHT + sALERT_MARGIN_FROM_TOP + sALERT_BUTTON_Y_PADDING) : pYAxis + CGFloat(sALERT_BUTTON_Y_PADDING)
        } else {
            width = sALERT_WIDTH - Int(sALERT_MARGIN_FROM_LEFT * 2)
        }
        let button = UIButton.init(frame: CGRect(x:xAxis, y:Int(yAxis), width: width, height:sALERT_BUTTON_HEIGHT))
        button.setTitle(pTitle, for: .normal)
        button.tag = pIndex
        button.setTitleColor(sALERT_COLOR, for: .normal)
        button.addTarget(self, action: #selector(CMAlertController.buttonClicked), for: .touchUpInside)
        addBorderTo(button.layer)
        return button
    }
    
    /**
     Add Custimization to layer includes border color , corder width , corner radius
     @param pLayer layer add effect
     */
   private func addBorderTo(_ pLayer: CALayer) {
        pLayer.cornerRadius = CGFloat(sALERT_VIEW_CORNER_RADIUS)
        pLayer.borderWidth = CGFloat(sALERT_VIEW_BORDER_WIDTH)
        pLayer.borderColor = sALERT_COLOR.cgColor
    }
    
    /**
     Button Clicked action
     @return Callback to completeHandler
     */
   @objc func buttonClicked(_ sender: UIButton)  {
        if let retunCallBack = callBack {
            retunCallBack!(sender)
        }
        dismissController()
    }
    
}
