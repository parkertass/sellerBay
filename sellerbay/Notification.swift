//
//  Notification.swift
//  sellerbay
//
//  Created by Tassapon Temahivong on 7/30/17.
//  Copyright © 2017 Tassapon Temahivong. All rights reserved.
//

import UIKit
import Rapid

class Notification: NSObject {
  var id: String?
  var message: String = ""
  var user: String = ""
  var isRead: Bool = false
  
  init(message: String, username: String, save: Bool = false) {
    self.message = message
    self.user = username
    
    if save {
      let dictionary: [String: Any] = [
        "message": message,
        "user": username,
        "isRead": isRead,
      ]
      
      Rapid.collection(named: Constants.NOTIFICATION)
        .newDocument()
        .mutate(value: dictionary) { result in
          switch result {
          case .success:
            print("Create Notification Success")
            
          case .failure(let error):
            switch error {
            case .timeout:
              print("Mutation timed out")
              
            case .permissionDenied(let message):
              print("Permission denied: \(String(describing: message))")
              
            default:
              print("Error occured: \(error)")
            }
          }
      }
    }
  }
  
  func setId(id: String) {
    self.id = id
  }
}
