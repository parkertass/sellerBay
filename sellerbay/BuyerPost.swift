//
//  BuyerPost.swift
//  sellerbay
//
//  Created by Tassapon Temahivong on 7/29/17.
//  Copyright © 2017 Tassapon Temahivong. All rights reserved.
//

import UIKit
import Rapid

class BuyerPost {
  var id: String?
  var name: String
  var descript: String
  var price: Double

  var user: User
  var isSold: Bool = false
  var soldDate: Date?

  init(name: String, description: String = "", price: Double, user: String, isForSave: Bool = false) {

    self.name = name
    descript = description
    self.price =  price
    self.user = User(name: user)
    
    if isForSave {
      let postDict: [String: Any] = [
        "name": name,
        "description": descript,
        "price": price,
        "user": user,
        "isSold": isSold,
        "sellers": "",
      ]
      
      Rapid.collection(named: "BuyerPost")
        .newDocument()
        .mutate(value: postDict) { result in
          switch result {
          case .success:
            print("Success")
            
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

//  func getDictionary() -> [String: Any] {
//    return [
//      "name": name,
//      "description": descript,
//      "price": price,
//      "user": user,
//      "isSold": isSold,
//      "soldDate": soldDate ?? Date()
//    ]
//  }
}
