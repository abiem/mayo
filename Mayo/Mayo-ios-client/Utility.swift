//
//  Utility.swift
//  Mayo-ios-client
//
//  Created by Lakshmi Kodali on 08/12/17.
//  Copyright © 2017 Weijie. All rights reserved.
//

// Utility file contain common functions used in application

import Foundation
import UIKit


/**
 Return Top view Controller
 */
func topController() -> UIViewController? {
    // recursive follow
    func follow(from:UIViewController?) -> UIViewController? {
        if let to = (from as? UITabBarController)?.selectedViewController {
            return follow(from: to)
        } else if let to = (from as? UINavigationController)?.visibleViewController {
            return follow(from: to)
        } else if let to = from?.presentedViewController {
            return follow(from: to)
        }
        return from
    }
    let root = UIApplication.shared.keyWindow?.rootViewController
    
    return follow(from: root)
    
}


func setToSuperView(_ pNewView: UIView , pParentView: UIView) {
    pNewView.translatesAutoresizingMaskIntoConstraints = false
    let horizontalConstraint = NSLayoutConstraint(item: pNewView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: pParentView, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0)
    let verticalConstraint = NSLayoutConstraint(item: pNewView, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: pParentView, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0)
    let widthConstraint = NSLayoutConstraint(item: pNewView, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: pParentView, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: 0)
    let heightConstraint = NSLayoutConstraint(item: pNewView, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: pParentView, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: 0)
    pParentView.addConstraints([horizontalConstraint, verticalConstraint, widthConstraint, heightConstraint])
}



