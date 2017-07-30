//
//  NotificationViewController.swift
//  sellerbay
//
//  Created by Tassapon Temahivong on 7/30/17.
//  Copyright © 2017 Tassapon Temahivong. All rights reserved.
//

import UIKit
import Rapid

class NotificationViewController: UIViewController {

  
  @IBOutlet weak var tableView: UITableView!
  var shownNotifications: [Notification] = []
  override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    Rapid.collection(named: Constants.NOTIFICATION)
    .filter(by: RapidFilter.equal(keyPath: "user", value: (globalUser?.name)!))
    .order(by: RapidOrdering(keyPath: RapidOrdering.docCreatedAtKey, ordering: .descending))
    .subscribe { results in
      switch results {
      case .success(let notifications):
        self.setNotifications(notifications: notifications)

      case .failure(let error):
        print("error")
        print(error)
      }
    }
    
    tableView.delegate = self
    tableView.dataSource = self
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  func setNotifications(notifications: [RapidDocument]) {
    shownNotifications = []
    for notification in notifications {
      let notiValue = notification.value
      let newNoti = Notification(message: notiValue?["message"] as! String, username: notiValue?["user"] as! String)
      shownNotifications.append(newNoti)
    }
    tableView.reloadData()
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

extension NotificationViewController: UITableViewDelegate, UITableViewDataSource {
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return shownNotifications.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    // Table view cells are reused and should be dequeued using a cell identifier.
    let cellIdentifier = "notificationCell"
    let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
    
    let noti = shownNotifications[indexPath.row]
    cell.textLabel?.text = noti.message
    return cell
  }
}
