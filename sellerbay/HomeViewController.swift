//
//  HomeViewController.swift
//  sellerbay
//
//  Created by Tassapon Temahivong on 7/30/17.
//  Copyright © 2017 Tassapon Temahivong. All rights reserved.
//

import UIKit
import Rapid

class HomeViewController: UIViewController {
  var rapidSubscription: RapidSubscription?
  var shownBuyerPosts: [BuyerPost] = []
  var chosenIndex: Int?

  
  @IBOutlet weak var resultText: UILabel!
  @IBOutlet weak var resultCount: UILabel!
  @IBOutlet weak var searchBar: UISearchBar!
  @IBOutlet weak var tableView: UITableView!
  override func viewDidLoad() {
    super.viewDidLoad()

//     Do any additional setup after loading the view.
    searchBar.delegate = self
    tableView.delegate = self
    tableView.dataSource = self
  
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    if globalUser == nil {
      performSegue(withIdentifier: "firstTimeUser", sender: self)
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    if justCreatePost {
      let alert = UIAlertController(title: "Alert", message: "Your buying request is successfully created", preferredStyle: UIAlertControllerStyle.alert)
      alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
      self.present(alert, animated: true, completion: nil)
      justCreatePost = false
    }
  }


  /*
  // MARK: - Navigation

  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
  }
  */
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "showBuyerPostDetail" {
      let destinationVC = segue.destination as! BuyerPostDetailViewController
      let post = shownBuyerPosts[sender as! Int]
      destinationVC.buyerPost = post
    }
  }

}

extension HomeViewController: UISearchBarDelegate ,UITableViewDelegate, UITableViewDataSource {
  func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
    searchBar.endEditing(true)
  }
  
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    searchBar.endEditing(true)
    searchBar.resignFirstResponder()
  }
  
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    if searchText != "" {
      let keywords = searchText.components(separatedBy: " ")
      let rapidFilters = keywords.map {RapidFilter.contains(keyPath: "name", subString: $0)}
      
      rapidSubscription = Rapid.collection(named: Constants.BUYER_POST)
        .filter(by: RapidFilter.or(rapidFilters))
        .subscribe { results in
          switch results {
          case .success(let posts):
            self.filterPosts(posts: posts, searchText: searchText)
            
          case .failure(let error):
            print("error")
            print(error)
          }
      }
    }

  }
  
  func filterPosts(posts: [RapidDocument], searchText: String) {
    shownBuyerPosts = []
    for post in posts {
      let postValue = post.value
      let newPost = BuyerPost(name: postValue?["name"] as! String, description: postValue?["description"] as! String, price: postValue?["price"] as! Double, user: postValue?["user"] as! String, isForSave: false)
      newPost.setId(id: post.id)
      shownBuyerPosts.append(newPost)
    }
    if shownBuyerPosts.count > 0 {
      resultCount.text = String(shownBuyerPosts.count)
      resultText.text = "Search results:"
    } else {
      resultCount.text = ""
      resultText.text = "Result not found"
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
    // Table view cells are reused and should be dequeued using a cell identifier.
    let cellIdentifier = "buyerPostCell"
    let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! SearchResultTableViewCell

    let post = shownBuyerPosts[indexPath.row]
    cell.itemName.text = post.name
    cell.itemDescription.text = post.descript
    cell.itemPrice.text = String(post.price)
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    performSegue(withIdentifier: "showBuyerPostDetail", sender: indexPath.row)
  }
}
