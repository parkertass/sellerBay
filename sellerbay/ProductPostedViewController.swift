//
//  ProductPostedViewController.swift
//  sellerbay
//
//  Created by Tassapon Temahivong on 7/29/17.
//  Copyright © 2017 Tassapon Temahivong. All rights reserved.
//

import UIKit

class ProductPostedViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  @IBAction func addMoreProduct(_ sender: UIButton) {
    dismiss(animated: true, completion: nil)
//    navigationController?.popViewController(animated: true)
//    let buyerPostVC = navigationController?.topViewController as! BuyerPostViewController
//    buyerPostVC.itemName.text = ""
//    buyerPostVC.itemDescription.text = ""
//    buyerPostVC.itemPrice.text = ""
  }

  /*
  // MARK: - Navigation

  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
  }
  */

}
