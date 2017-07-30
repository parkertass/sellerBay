//
//  BuyerPostViewController.swift
//  sellerbay
//
//  Created by Tassapon Temahivong on 7/29/17.
//  Copyright © 2017 Tassapon Temahivong. All rights reserved.
//

import UIKit

class BuyerPostViewController: UIViewController {

  @IBOutlet weak var itemName: UITextField!
  @IBOutlet weak var itemDescription: UITextView!
  @IBOutlet weak var itemPrice: UITextField!
  @IBOutlet weak var postButton: UIButton!
  var firstTime: Bool = true
  
  @IBOutlet weak var scrollView: UIScrollView!
  override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    itemDescription.delegate = self
    scrollView.contentSize = CGSize(width: self.view.frame.width, height: self.view.frame.height+100)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    itemName.text = ""
    itemDescription.text = "Ex. Wooden Table, at least 1 meter tall"
    firstTime = true
    itemDescription.textColor = .gray
    itemPrice.text = ""
    validateButton()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func validateButton() {
    if ((itemName.text != "") && (itemPrice.text != "")) {
      postButton.isEnabled = true
    } else {
      postButton.isEnabled = false
    }
  }

  @IBAction func itemNameEditingDidChange(_ sender: UITextField) {
    validateButton()
  }
  
  @IBAction func priceEditingDidChange(_ sender: UITextField) {
    validateButton()
  }

  @IBAction func postBuyerItem(_ sender: Any) {
    if let name = itemName.text,
      let price = itemPrice.text,
      let user = globalUser {
      var _ = BuyerPost(name: name, description: itemDescription.text, price: Double(price)!, user: user.name, isForSave: true)
    }
  }
  
  // Scroll text when typing
  func registerForKeyboardNotifications(){
    //Adding notifies on keyboard appearing
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
  }
  
  func deregisterFromKeyboardNotifications(){
    //Removing notifies on keyboard appearing
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
  }
  
  func keyboardWasShown(notification: NSNotification){
    //Need to calculate keyboard exact size due to Apple suggestions
    self.scrollView.isScrollEnabled = true
    var info = notification.userInfo!
    let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
    let contentInsets : UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize!.height, 0.0)
    
    self.scrollView.contentInset = contentInsets
    self.scrollView.scrollIndicatorInsets = contentInsets
    
    var aRect : CGRect = self.view.frame
    aRect.size.height -= keyboardSize!.height
    if let activeField = self.itemPrice {
      if (!aRect.contains(activeField.frame.origin)){
        self.scrollView.scrollRectToVisible(activeField.frame, animated: true)
      }
    }
  }
  
  func keyboardWillBeHidden(notification: NSNotification){
    //Once keyboard disappears, restore original positions
    var info = notification.userInfo!
    let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
    let contentInsets : UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, -keyboardSize!.height, 0.0)
    self.scrollView.contentInset = contentInsets
    self.scrollView.scrollIndicatorInsets = contentInsets
    self.view.endEditing(true)
    self.scrollView.isScrollEnabled = false
  }
  
  func textFieldDidBeginEditing(_ textField: UITextField){
    itemPrice = textField
  }
  
  func textFieldDidEndEditing(_ textField: UITextField){
    itemPrice = nil
  }


  /*
  // MARK: - Navigation

  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
  }
  */
  
  @IBAction func onBack(_ sender: Any) {
    dismiss(animated: true, completion: nil)
  }

}

extension BuyerPostViewController: UITextViewDelegate, UITextFieldDelegate {
  func textViewDidBeginEditing(_ textView: UITextView) {
    if firstTime {
      itemDescription.textColor = .black
      itemDescription.text = ""
      firstTime = false
    }
  }
  
  func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
    if(text == "\n") {
      textView.resignFirstResponder()
      return false
    }
    return true
  }
  
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
}

