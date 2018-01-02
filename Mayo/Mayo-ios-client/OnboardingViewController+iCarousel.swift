//
//  File.swift
//  Mayo-ios-client
//
//  Created by Lakshmi Kodali on 20/12/17.
//  Copyright © 2017 Weijie. All rights reserved.
//

import Foundation
import UIKit
import iCarousel

extension OnboardingViewController: iCarouselDelegate, iCarouselDataSource  {
 
  func numberOfItems(in carousel: iCarousel) -> Int {
    return 4
  }
  
  func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
    let view = UIView()
    let viewHeight  = UIScreen.main.bounds.size.height <= 568 ? 180 : 212
    let viewWidth  = UIScreen.main.bounds.size.height <= 568 ? 265 : 335
    let carouselSize = mCarousel.frame.size
    view.frame = CGRect(x:0, y:0, width: viewWidth , height:viewHeight)
     let tempView = GradientView(frame: CGRect(x: 10, y: 10, width: viewWidth , height:viewHeight))
    
    // Create Lable
    let label = UILabel()
    label.frame = CGRect(x:20, y:10, width: tempView.frame.size.width - 40, height:50)
    label.text = Constants.INTRO_TITLE_ARRAY[index]
    let fontSize  = UIScreen.main.bounds.size.height <= 568 ? 20 : 24
    label.font = UIFont.systemFont(ofSize: CGFloat(fontSize))
    label.textAlignment = .left
    label.numberOfLines = 0
    label.textColor = .white
    label.sizeToFit()
    tempView.addSubview(label)
    
    //Create Button
    let button = UIButton()
    button.frame = CGRect(x:20, y:tempView.frame.size.height - 60 , width: tempView.frame.size.width - 40 , height:45)
    button.setTitle(Constants.INTRO_BUTTON_TITLE_ARRAY[index], for: .normal)
    button.tag = index
    button.layer.cornerRadius = 4
    button.layer.borderWidth = 2
    button.layer.borderColor = UIColor.white.cgColor
    tempView.addSubview(button)
    button.addTarget(self, action: #selector(self.moveToNextIndex), for: .touchUpInside)
    tempView.startColor = UIColor.hexStringToUIColor(hex: Constants.INTRO_START_COLOR_ARRAY[index])
    tempView.endColor = UIColor.hexStringToUIColor(hex: Constants.INTRO_END_COLOR_ARRAY[index])
    view.addSubview(tempView)
    
    view.backgroundColor = UIColor.clear
    view.layer.shadowColor = UIColor.black.cgColor
    view.layer.shadowOffset = CGSize(width: 0, height: 10)
    view.layer.shadowOpacity = 0.3
    view.layer.shadowRadius = 15.0
    
    return view
  }
  
  func moveToNextIndex(_ sender: UIButton) {
    if sender.tag != 3 {
      if sender.tag == 2 {
        CMAlertController.sharedInstance.showImageCustomisedAlert(Constants.INTRO_LOCATION_ALERT_TITLE, #imageLiteral(resourceName: "LocationAlertImage"), Constants.INTRO_LOCATION_ALERT_SUBTITLE, [Constants.INTRO_LOCATION_ALERT_BUTTON_TITLE], { (button) in
            self.mCarousel.scrollToItem(at: sender.tag + 1, animated: true)
            })
      } else {
         mCarousel.scrollToItem(at: sender.tag + 1, animated: true)
      }
    } else {
      askForLocationAuth()
    }
  }
  
  func carouselCurrentItemIndexDidChange(_ carousel: iCarousel) {
    stopAnimationAnimation()
    mImageView.isHidden = false
    mBackgroundAnimation.isHidden = false
    mBackgroundAnimation.transform = CGAffineTransform.identity
    if carousel.currentItemIndex == 1 {
      showUserThankedAnimation()
    } else if carousel.currentItemIndex == 2 {
//      showRippleAnimation(#imageLiteral(resourceName: "centerWhiteDot"), #imageLiteral(resourceName: "ripple"))
      showSecondPinAnimation()
    } else if carousel.currentItemIndex == 3 {
//      showRippleAnimation(nil, #imageLiteral(resourceName: "rippleHorizontalAngle"))
      showThirdPinAnimation()
    }

  }
  
  func carousel(_ carousel: iCarousel, valueFor option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
    if option == iCarouselOption.spacing {
      return value * 1.03
    }
    
    return value
  }

}
