//
//  IntroCollectionCell.swift
//  Mayo-ios-client
//
//  Created by Lakshmi Kodali on 20/12/17.
//  Copyright © 2017 Weijie. All rights reserved.
//

import UIKit

protocol IntroCollectionCellDelegate: class {
  func introSelectedButton(_ sender: UIButton)
}



class IntroCollectionCell: UICollectionViewCell {
    
  @IBOutlet private weak var mButtonMove: DesignableButton!
  @IBOutlet private weak var mLabelTitle: UILabel!
  weak var mDelegate: IntroCollectionCellDelegate?
  
  
  public func updateCell (_ labelText: String, _ buttonText:String, _ delegate: UIViewController) {
    self.mLabelTitle.text = labelText
    self.mButtonMove.setTitle(buttonText, for: .normal)
    mButtonMove.tag = self.tag
    mButtonMove.addTarget(self, action: #selector(self.moveToNext), for: .touchUpInside)
    mDelegate = delegate as? IntroCollectionCellDelegate
  }
  
  @objc private func moveToNext(_ sender : UIButton) {
    print("Button Called")
    if let delegate = mDelegate {
      delegate.introSelectedButton(sender)
    }
  }
  
  
}
