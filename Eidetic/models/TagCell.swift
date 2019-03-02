//
//  TagCell.swift
//  Eidetic
//
//  Created by user147964 on 1/27/19.
//  Copyright © 2019 user145467. All rights reserved.
//

import UIKit

class TagCell: UICollectionViewCell {
    
    @IBOutlet weak var myLabel: UILabel!
    @IBOutlet weak var deleteTagButton: UIButton!
    
    override func awakeFromNib() {
        self.backgroundColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
        self.myLabel.textColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        self.layer.cornerRadius = 4
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
}
