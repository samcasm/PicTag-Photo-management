//
//  ReminderCell.swift
//  Eidetic
//
//  Created by user147964 on 2/22/19.
//  Copyright © 2019 user145467. All rights reserved.
//

import UIKit

protocol ReminderCellDelegate: AnyObject {
    func deleteReminder(cell: ReminderCell)
}

class ReminderCell: UITableViewCell {

    @IBOutlet weak var thumbnailImage: UIImageView!
    @IBOutlet weak var reminderLabel: UILabel!
    var reminderID: String!
    
    weak var delegate: ReminderCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    @IBAction func deleteReminderAction(_ sender: UIButton) {
        delegate?.deleteReminder(cell: self)
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}


   
