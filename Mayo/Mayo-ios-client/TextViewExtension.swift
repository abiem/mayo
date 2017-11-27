//
//  TextViewExtension.swift
//  Mayo-ios-client
//
//  Created by abiem  on 5/25/17.
//  Copyright © 2017 abiem. All rights reserved.
//

import UIKit

extension MainViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.alpha == 0.5 {
            textView.text = nil
            textView.alpha = 1
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "What do you need help with?"
            textView.alpha = 0.5
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        
        
        // change the post button isEnabled
        // if there is text inside the textView
        // also check that it is alpha of 1 so it is not the placeholder
        if textView.alpha == 1 && textView.text.count > 0 {
            
            if let post_new_task_button = self.view.viewWithTag(self.POST_NEW_TASK_BUTTON_TAG) as? UIButton {
                if let cancelButton = self.view.viewWithTag(self.CURRENT_USER_CANCEL_BUTTON) as? UIButton {
                    cancelButton.isEnabled = true
                }
                // set post new task button to enabled
                post_new_task_button.isEnabled = true
                // change the alpha for the button to 1
                post_new_task_button.alpha = 1.0
                
            }
            
        } else {
            // if character check is not satisfired or alpha == 1 not satisfied
            // disable the post button
            
            if let post_new_task_button = self.view.viewWithTag(self.POST_NEW_TASK_BUTTON_TAG) as? UIButton {
                
                if let cancelButton = self.view.viewWithTag(self.CURRENT_USER_CANCEL_BUTTON) as? UIButton {
                    cancelButton.isEnabled = false
                }
                // set post new task button to enabled
                post_new_task_button.isEnabled = false
                
                // change alpha to 0.5 for the post button
                post_new_task_button.alpha = 0.5
                
            }
        }
        
        
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        let maxtext: Int = 78

        //If the text is larger than the maxtext, the return is false
//        if range.length > 0 && text == "" {
//            textView.text = (textView.text as NSString).substring(to: textView.text.count - 1)
//        }
//        else if textView.text.count < maxtext {
//           textView.text = textView.text + text
//        }
//        return false
        
        return textView.text.count + (text.count - range.length) <= maxtext
    }
    
}

