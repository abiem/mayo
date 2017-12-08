//
//  CMAlertController.swift
//  Mayo-ios-client
//
//  Created by Lakshmi Kodali on 08/12/17.
//  Copyright © 2017 Weijie. All rights reserved.
//

import UIKit

class CMAlertController: NSObject {

    var mAlertBackgroundView = UIView()
    
    class var sharedInstance: CMAlertController {
        struct Static {
            static let instance = CMAlertController()
        }
        return Static.instance
    }
    
    func showAlert(_ pTitle: String, _ pSubtitle: String, _ pButtonArray:[String]) {
        createAlertView(pTitle, pSubtitle, pButtonArray)
    }
    
   private func createAlertView(_ pTitle: String, _ pSubtitle: String, _ pButtonArray:[String]) {
    if let parentView = topController()?.view {
        if !parentView.subviews.contains(mAlertBackgroundView) {
            mAlertBackgroundView.frame = parentView.frame
            mAlertBackgroundView.backgroundColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 0.3221050942)
            parentView.addSubview(mAlertBackgroundView)
            
            let alertView = UIView()
            //setConstraints(alertView, pParentView:parentView )
            }
        }
    
    }
    
    
}
