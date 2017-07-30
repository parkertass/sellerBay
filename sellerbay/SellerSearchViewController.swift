//
//  SellerSearchViewController.swift
//  sellerbay
//
//  Created by Tassapon Temahivong on 7/29/17.
//  Copyright © 2017 Tassapon Temahivong. All rights reserved.
//

import UIKit
import Rapid

class SellerSearchViewController: UIViewController {

  var shownBuyerPosts: [BuyerPost] = []
  var currentSubscription: RapidSubscription?
  
  @IBOutlet weak var searchBar: UISearchBar!
  @IBOutlet weak var resultText: UILabel!
  @IBOutlet weak var tableView: UITableView!

  override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    searchBar.delegate = self
    tableView.dataSource = self
    tableView.delegate = self
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

extension SellerSearchViewController: UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    if currentSubscription != nil {
      currentSubscription?.unsubscribe()
      currentSubscription = nil
    }
    if (searchText == "") {
      return;
    }
    
    let keywords = searchText.components(separatedBy: " ")
    let rapidFilters = keywords.map { RapidFilter.contains(keyPath: "name", subString: $0) }
//    let rapidFilters = keywords.map { RapidFilter.equal(keyPath: "name", value: $0) }
    
    
    currentSubscription = Rapid.collection(named: "BuyerPost")
      .filter(by: RapidFilter.or(rapidFilters))
      .subscribe { result in
        switch result {
        case .success(let posts):
          // TODO: update user interface
          print("success")
          self.filterPosts(posts: posts, searchText: searchText)
          
        case .failure(let error):
          // once the result is equal to `.failure` the subscription is automatically canceled
          // and will no longer receive and updates
          switch error {
          case .permissionDenied(let message):
            print("Permission denied: \(String(describing: message))")
            
          default:
            print("Error occured")
          }
        }
    }
  }
  
  func filterPosts(posts: [RapidDocument], searchText: String) {
    shownBuyerPosts = []
//    tableView.de
    for post in posts {
      let postValue = post.value
      let newPost = BuyerPost(name: postValue?["name"] as! String, description: postValue?["description"] as! String, price: postValue?["price"] as! Double, user: postValue?["user"] as! String)
      print(newPost)
//      let newIndexPath = NSIndexPath(row: shownBuyerPosts.count, section: 0)
      shownBuyerPosts.append(newPost)
    }
    tableView.reloadData()
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return shownBuyerPosts.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    print("in fuck")
    // Table view cells are reused and should be dequeued using a cell identifier.
    let cellIdentifier = "BuyerPostCell"
    let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! SearchResultTableViewCell
    
    let buyerPost = shownBuyerPosts[indexPath.row]
    cell.itemName.text = buyerPost.name
    cell.itemDescription.text = buyerPost.descript
    cell.itemPrice.text = String(buyerPost.price)
    print(cell)
    
    return cell
  }
}

