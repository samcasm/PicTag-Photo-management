//
//  BackupScreen.swift
//  Eidetic
//
//  Created by user147964 on 2/19/19.
//  Copyright © 2019 user145467. All rights reserved.
//

import Foundation
import UIKit
import CloudKit

class BackupScreen: UIViewController {
    
    
    @IBOutlet weak var saveDataToiCloudButton: UIButton!
    @IBOutlet weak var getSavedDataButton: UIButton!
    
    let database = CKContainer.default().privateCloudDatabase
    
    override func viewDidLoad() {
        print("View loaded")
        self.title = "iCloud Backup"
        
    }
    
    @IBAction func sendDataToCloudAction(_ sender: UIButton) {
        do{
            let allTagsData = try String(contentsOf: FileManager.tagsFileURL, encoding: .utf8)
            let allFoldersData = try String(contentsOf: FileManager.directoriesURL, encoding: .utf8)
            
            overwriteTagsDataInDatabase(allTags: allTagsData, allFolders: allFoldersData)
            
        }catch{
            print("Couldn't fetch data to save")
        }
    }
    
    @IBAction func getDataFromCloudAction(_ sender: UIButton) {
        let recordID = CKRecord.ID(recordName: "EideticData")
        
        database.fetch(withRecordID: recordID) { record, error in
            if let record = record, error == nil {
                do{
                    try self.writeRecordDataToAppData(key: "Tags", record: record)
                    try self.writeRecordDataToAppData(key: "Folders", record: record)
                    self.showAlertWith(title: "Success!", message: "Retrieved your data successfully")
                }catch{
                    print("Error call")
                    self.showAlertWith(title: "Failed!", message: "Something went wrong while trying to retrieve data")
                }
            }else if error != nil{
                let ckerror = error as! CKError
                if ckerror.code == CKError.notAuthenticated {
                    self.showAlertWith(title: "Failed!", message: "You are not signed in to your apple account. Sign In in the settings menu")
                }else if ckerror.code == CKError.unknownItem{
                    self.showAlertWith(title: "Failed", message: "No data backup is available in your iCloud")
                }else{
                    self.showAlertWith(title: "Failed", message: "Something went wrong trying to retrieve your backup data")
                }
            }
        }
    }
    
    func overwriteTagsDataInDatabase(allTags: String, allFolders: String){

        let recordID = CKRecord.ID(recordName: "EideticData")
        
        database.fetch(withRecordID: recordID) { record, error in
            
            if let record = record, error == nil {
                
                //update your record here
                record.setValue(allTags, forKey: "Tags")
                record.setValue(allFolders, forKey: "Folders")
                
                self.database.save(record) { (record, error) in
                    if error != nil {
                        self.showAlertWith(title: "Failed!", message: "Something went wrong while saving your data to iCloud")
                    }
                    guard record != nil else {return}
                    print("record saved!")
                    self.showAlertWith(title: "Success!", message: "Your data is now backed up")
                }
            }else if error != nil {
                let ckerror = error as! CKError
                if ckerror.code == CKError.unknownItem {
                    let newTagsRecord = CKRecord(recordType: "EideticData", recordID: CKRecord.ID(recordName: "EideticData"))
                    newTagsRecord.setValue(allTags, forKey: "Tags")
                    newTagsRecord.setValue(allFolders, forKey: "Folders")
                    
                    self.database.save(newTagsRecord) { (record, error) in
                        if error != nil {
                            self.showAlertWith(title: "Failed!", message: "Something went wrong while saving your data to iCloud")
                        }
                        guard record != nil else {return}
                        print("record saved!")
                        self.showAlertWith(title: "Success!", message: "Your data is now backed up")
                    }
                }else if ckerror.code == CKError.notAuthenticated {
                    self.showAlertWith(title: "Failed!", message: "You are not signed in to your apple account. Sign In in the settings menu")
                }else{
                    self.showAlertWith(title: "Failed", message: "Something went wrong trying to retrieve your backup data")
                }
            }
        }
    }
    
    func writeRecordDataToAppData(key: String, record: CKRecord) throws {
        let tagsRecord = record.object(forKey: key)
        let tagsString = tagsRecord as! String
        
        let tagsData = tagsString.data(using: .utf8) as! Data
        let decoder = JSONDecoder()
        let encoder = JSONEncoder()
        
        if key == "Tags"{
            let decodedJson = try decoder.decode([Images].self, from: tagsData)
            let encodedJSON = try encoder.encode(decodedJson)
            try encodedJSON.write(to: FileManager.tagsFileURL, options: .atomic)
        }else{
            let decodedJson = try decoder.decode([Directory].self, from: tagsData)
            let encodedJSON = try encoder.encode(decodedJson)
            try encodedJSON.write(to: FileManager.directoriesURL, options: .atomic)
        }
    }
    
    
}
