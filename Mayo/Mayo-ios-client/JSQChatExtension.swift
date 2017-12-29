//
//  JSQChatExtension.swift
//  Mayo-ios-client
//
//  Created by Lakshmi Kodali on 29/12/17.
//  Copyright © 2017 Weijie. All rights reserved.
//

import Foundation
import UIKit
import JSQMessagesViewController

extension JSQMessagesInputToolbar {
  override open func didMoveToWindow() {
    super.didMoveToWindow()
    if #available(iOS 11.0, *) {
      if self.window?.safeAreaLayoutGuide != nil {
        self.bottomAnchor.constraintLessThanOrEqualToSystemSpacingBelow((self.window?.safeAreaLayoutGuide.bottomAnchor)!, multiplier: 1.0).isActive = true
      }
    }
  }
}
