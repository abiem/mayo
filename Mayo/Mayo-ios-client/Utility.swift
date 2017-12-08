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

func setConstraints(_ pNewView: UIView , pParentView: UIView) {
    pNewView.translatesAutoresizingMaskIntoConstraints = false
    let horizontalConstraint = NSLayoutConstraint(item: pNewView, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: pParentView, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0)
    let verticalConstraint = NSLayoutConstraint(item: pNewView, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: pParentView, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0)
    let widthConstraint = NSLayoutConstraint(item: pNewView, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 100)
    let heightConstraint = NSLayoutConstraint(item: pNewView, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 100)
    pParentView.addConstraints([horizontalConstraint, verticalConstraint, widthConstraint, heightConstraint])
}



