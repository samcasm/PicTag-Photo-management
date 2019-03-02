//
//  RemindersViewController.swift
//  Eidetic
//
//  Created by user147964 on 2/22/19.
//  Copyright © 2019 user145467. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications
import Photos

class RemindersViewController: UITableViewController, ReminderCellDelegate {

    var scheduledReminders: [UNNotificationRequest] = []
    var reminders: [Reminder] = []
    
    struct Reminder {
        var phasset: PHAsset
        var scheduledDate: String
    }
    
    func deleteReminder(cell: ReminderCell) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [cell.reminderID])
        fetchCurrentUserNotifications()
    }
    
    func fetchCurrentUserNotifications(){
        UNUserNotificationCenter.current().getPendingNotificationRequests { (notifications) in
            
            print(notifications.count)
            self.scheduledReminders = notifications
            DispatchQueue.main.async {
                self.reminders =  self.scheduledReminders.map {
                    let asset = PHAsset.fetchAssets(withLocalIdentifiers: [$0.identifier], options: nil).firstObject as! PHAsset
                    return Reminder(phasset: asset, scheduledDate: $0.content.body)
                }
                self.tableView.reloadData()
            }
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        self.title = "Reminders List"
        fetchCurrentUserNotifications()
    }
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if reminders.count == 0 {
            self.tableView.separatorStyle = .none
            self.tableView.setEmptyMessage("No reminders set yet")
            return 0
        } else {
            self.tableView.separatorStyle = .singleLine
            self.tableView.restore()
            return reminders.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let asset = reminders[indexPath.row].phasset
        let cell = tableView.dequeueReusableCell(withIdentifier: "reminderCell", for: indexPath) as! ReminderCell
        cell.delegate = self
        
        PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFit, options: nil) { (image, _) in
            
            cell.thumbnailImage.image = image
            cell.reminderLabel.text = self.reminders[indexPath.row].scheduledDate
            cell.reminderID = asset.localIdentifier
        }
        return cell
    }
}
