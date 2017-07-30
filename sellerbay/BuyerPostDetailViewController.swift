//
//  BuyerPostDetailViewController.swift
//  sellerbay
//
//  Created by Tassapon Temahivong on 7/30/17.
//  Copyright © 2017 Tassapon Temahivong. All rights reserved.
//

import UIKit
import Rapid

var justCreatePost = false;

class BuyerPostDetailViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

  let imagePicker = UIImagePickerController()
  var buyerPost: BuyerPost?
  var hasImage: Bool = false
  @IBOutlet weak var itemName: UILabel!
  @IBOutlet weak var itemDescription: UILabel!
  @IBOutlet weak var itemPrice: UILabel!
  @IBOutlet weak var itemImage: UIImageView!
  
  @IBOutlet weak var selectImageButton: UIButton!
  @IBOutlet weak var submitButton: UIButton!
//  @IBOutlet weak var selectImageButtonLabel: UILabel!
//  @IBOutlet weak var submitButtonLabel: UILabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    itemName.text = buyerPost?.name
    itemDescription.text = buyerPost?.descript
    itemPrice.text = String((buyerPost?.price)!)

    imagePicker.delegate = self
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    selectImageButton.isHidden = false
//    selectImageButtonLabel.isHidden = false
    submitButton.isHidden = false
//    submitButtonLabel.isHidden = true
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  @IBAction func onBack(_ sender: UIButton) {
    dismiss(animated: true, completion: nil)
  }
  
  
  @IBAction func onSubmit(_ sender: Any) {
    Rapid.collection(named: Constants.BUYER_POST)
      .document(withID: (buyerPost?.id)!)
      .fetch { result in
        switch result {
        case .success(let post):
          print("fetch successful")
          if let currentSellers = post.value!["sellers"] {
            self.addSeller(currentSellers: currentSellers as! String)
          } else {
            self.addSeller(currentSellers: "")
          }
        case .failure(let error):
          print(error)
        }
        
    }

    justCreatePost = true
    dismiss(animated: true, completion: nil)
  }
  
  func addSeller(currentSellers: String) {
    let updatedSellers: String = currentSellers + globalUser!.name + " "
    let updatedValue: [String: Any] = ["sellers": updatedSellers]
    Rapid.collection(named: Constants.BUYER_POST)
      .document(withID: (buyerPost?.id)!)
      .merge(value: updatedValue) { result in
        switch result {
        case .success:
          print("Update sellers success")
          
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

  
  @IBAction func loadImageButtonTapped(sender: UIButton) {
    let alert = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
    alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
      self.openCamera()
    }))
    
    alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
      self.openGallary()
    }))
    
    alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
    
    self.present(alert, animated: true, completion: nil)
  }
  
  func openCamera() {
    imagePicker.allowsEditing = false
    imagePicker.sourceType = .camera
    
    present(imagePicker, animated: true, completion: nil)
  }
  func openGallary() {
    imagePicker.allowsEditing = false
    imagePicker.sourceType = .photoLibrary
    
    present(imagePicker, animated: true, completion: nil)
  }
  
  // MARK: - UIImagePickerControllerDelegate Methods
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
      itemImage.contentMode = .scaleAspectFit
      itemImage.image = pickedImage
      hasImage = true
      selectImageButton.setTitle("Reselect image", for: .normal)
//      selectImageButtonLabel.text = "Reselect Image"
        submitButton.isHidden = false
        submitButton.setTitle("Submit", for: .normal)
      //      submitButtonLabel.isHidden = false
    }
    
    dismiss(animated: true, completion: nil)
  }
  
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    dismiss(animated: true, completion: nil)
  }


  /*
   MARK: - Navigation

   In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     Get the new view controller using segue.destinationViewController.
     Pass the selected object to the new view controller.
  }
  */

}

