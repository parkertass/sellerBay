//
//  IntroViewController.swift
//  sellerbay
//
//  Created by Tassapon Temahivong on 7/29/17.
//  Copyright © 2017 Tassapon Temahivong. All rights reserved.
//

import UIKit
import Rapid

var shownNotifications: [Notification] = []

class IntroViewController: UIViewController {

  @IBOutlet weak var userNameText: UITextField!

  let dateFormatter = DateFormatter()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    userNameText.delegate = self
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"

    // Do any additional setup after loading the view.
//    print("in")
//    Rapid.collection(named: "BuyerPost")
//      .filter(by: RapidFilter.not(
//        RapidFilter.isNull(keyPath: "description")
//      ))
//      .subscribe { result in
//        switch result {
//        case .success(let posts):
//          print(posts.count)
//          //          for post in posts {
//          //            print(post.id)
//          //            Rapid.collection(named: "BuyerPost")
//          //              .document(withID: post.id)
//          //              .delete { result in
//          //                switch result {
//          //                case .success:
//          //                  print("Success")
//          //
//          //                case .failure(let error):
//          //                  print("Error occured: \(error)")
//          //                }
//          //            }
//        //          }
//        case .failure(let errors):
//          print(errors)
//        }
//    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }


  /*
  // MARK: - Navigation

  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
  }
  */

  @IBAction func signin(_ sender: UIButton) {

//    Rapid.collection(named: "User")
//      .fetch { result in
//        switch result {
//        case .success(let user):
//          print(user[0].value?["name"] as! String)
//        case .failure(let error):
//          print(error)
//        }
//    }

    if let name = userNameText.text {
      Rapid.collection(named: "User")
        .filter(by: RapidFilter.equal(keyPath: "name", value: name))
        .fetch { result in
          switch result {
          case .success(let user):
            if user.count > 0 {
              globalUser = User(name: name)
              print("User existed")
              self.updateNotification()
            }
            else {
              self.addUser(name: name)
            }
            
          case .failure(let error):
            print(error)
          }
      }
    }
  }

  func addUser(name: String) {
    let user: [String:Any] = ["name": name]
    Rapid.collection(named: "User")
      .newDocument()
      .mutate(value: user) { result in
        switch result {
        case .success:
          globalUser = User(name: name)
          print("Add user success")
          self.updateNotification()

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
  
  func updateNotification() {
    // Do any additional setup after loading the view.
    Rapid.collection(named: Constants.BUYER_POST)
      .filter(by: RapidFilter.equal(keyPath: "user", value: (globalUser?.name)!))
      .subscribe { result in
        switch result {
        case .success(let posts):
          self.updateNotiPosts(posts: posts)
          
        case .failure(let error):
          print(error)
        }
    }
  }
  
  func updateNotiPosts(posts: [RapidDocument]) {
    for (i, post) in posts.enumerated() {
      let postValue = post.value
      var numSellers: Int = 0
      var currentSellers: [String] = []
      if let sellers = postValue?["sellers"] {
        print(i)
        print(sellers)
        if sellers as! String == "" {
          numSellers = 0
        } else {
          currentSellers = (sellers as! String).components(separatedBy: " ")
          numSellers = currentSellers.count
        }
      } else {
        numSellers = 0
//        setEmptySellers(post.id)
      }
      
      var numNotiSeller: Int = 0
      if let notiSeller = postValue?["numNotiSeller"] {
        numNotiSeller = notiSeller as! Int
      }
      if (numSellers > numNotiSeller) {
        // Make new notifications
        createNotification(post, currentSellers: currentSellers)
      }
      
      // Set noti date
//      setNotiDate(post.id)
    }
  }
  
  func createNotification(_ post: RapidDocument, currentSellers: [String]) {
    var message: String = ""
    if currentSellers.count > 1 {
      message = "\(currentSellers.count) people are interested in your \(post.value?["name"] as! String)"
    } else {
      message = "1 person is interested in your \(post.value?["name"] as! String)"
    }
    let _ = Notification(message: message, username: (globalUser?.name)!, save: true)
    
    // Update num noti seller
    let dict: [String: Any] = [ "numNotiSeller": currentSellers.count];
    Rapid.collection(named: Constants.BUYER_POST)
      .document(withID: post.id)
      .merge(value: dict) { result in
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
  
  func setEmptySellers(_ id: String) {
    let dict: [String: Any] = ["sellers": ""]
    Rapid.collection(named: Constants.BUYER_POST)
      .document(withID: id)
      .merge(value: dict) { result in
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
  
  func setNotiDate(_ id: String) {
    let date = Date()
    let dict: [String: Any] = ["notiDate": dateFormatter.string(from: date as Date)]
    Rapid.collection(named: Constants.BUYER_POST)
      .document(withID: id)
      .merge(value: dict) { result in
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

extension IntroViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    userNameText.resignFirstResponder()
    return true
  }
}
