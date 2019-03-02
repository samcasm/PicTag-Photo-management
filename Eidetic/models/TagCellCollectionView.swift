//
//  TagCell.swift
//  Eidetic
//
//  Created by user145467 on 11/22/18.
//  Copyright © 2018 user145467. All rights reserved.
//

import UIKit

//1. delegate method
protocol TagCellDelegate: AnyObject {
    func deleteTag(cell: TagCellCollectionView)
}

class TagCellCollectionView: UICollectionViewCell {
    
    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var deleteTagButton: UIButton!

    //2. create delegate variable
    weak var delegate: TagCellDelegate?
    
    //3. assign this action to close button
    @IBAction func deleteTag(sender: AnyObject) {
        //4. call delegate method
        //check delegate is not nil with `?`
        delegate?.deleteTag(cell: self)
    }
}




