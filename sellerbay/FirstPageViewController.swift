//
//  FirstPageViewController.swift
//  sellerbay
//
//  Created by Tassapon Temahivong on 7/30/17.
//  Copyright © 2017 Tassapon Temahivong. All rights reserved.
//

import UIKit

class FirstPageViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    let delayInSeconds: Double = 2.0;
    
    let when = DispatchTime.now() + delayInSeconds // change 2 to desired number of seconds
    DispatchQueue.main.asyncAfter(deadline: when) {
      self.performSegue(withIdentifier: "toHomePage", sender: nil)
    }
  }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
