//
//  StringExtension.swift
//  Mayo-ios-client
//
//  Created by Lakshmi Kodali on 28/12/17.
//  Copyright © 2017 Weijie. All rights reserved.
//

import Foundation
import UIKit


extension String {
  
  func widthOfString(usingFont font: UIFont) -> CGFloat {
    let fontAttributes = [NSFontAttributeName: font]
    let size = (self as NSString).size(attributes: fontAttributes)
    return size.width
  }
  
  func heightOfString(usingFont font: UIFont) -> CGFloat {
    let fontAttributes = [NSFontAttributeName: font]
    let size = (self as NSString).size(attributes: fontAttributes)
    return size.height
  }

}
