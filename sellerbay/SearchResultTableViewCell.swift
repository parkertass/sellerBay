//
//  SearchResultTableViewCell.swift
//  sellerbay
//
//  Created by Tassapon Temahivong on 7/29/17.
//  Copyright © 2017 Tassapon Temahivong. All rights reserved.
//

import UIKit

class SearchResultTableViewCell: UITableViewCell {

  @IBOutlet weak var itemImage: UIImageView!
  @IBOutlet weak var itemName: UILabel!
  @IBOutlet weak var itemDescription: UILabel!
  @IBOutlet weak var itemPrice: UILabel!
  override func awakeFromNib() {
      super.awakeFromNib()
      // Initialization code
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
      super.setSelected(selected, animated: animated)

      // Configure the view for the selected state
  }

}
