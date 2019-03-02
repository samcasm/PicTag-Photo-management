//
//  controls.swift
//  Eidetic
//
//  Created by user145467 on 11/22/18.
//  Copyright © 2018 user145467. All rights reserved.
//

import Foundation
import UIKit
import Photos
import PhotosUI

extension UIViewController {
    
    func isAppsFirstLaunch()->String{
        let defaults = UserDefaults.standard
        
        if self is ViewController{
            if let _ = defaults.string(forKey: "ViewController"){
                return ""
            }else{
                defaults.set(true, forKey: "ViewController")
                return "ViewController"
            }
        }else if self is DirectoriesViewController{
            if let _ = defaults.string(forKey: "DirectoriesViewController"){
                return ""
            }else{
                defaults.set(true, forKey: "DirectoriesViewController")
                return "DirectoriesViewController"
            }
        }else if self is RemindersViewController{
            if let _ = defaults.string(forKey: "RemindersViewController"){
                return ""
            }else{
                defaults.set(true, forKey: "RemindersViewController")
                return "RemindersViewController"
            }
        }
        return ""
    }
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func showAlertWith(title: String, message: String){
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }

    
    func showInputDialog(title:String? = nil,
                         subtitle:String? = nil,
                         actionTitle:String? = "Add",
                         cancelTitle:String? = "Cancel",
                         inputPlaceholder:String? = nil,
                         inputKeyboardType:UIKeyboardType = UIKeyboardType.default,
                         cancelHandler: ((UIAlertAction) -> Swift.Void)? = nil,
                         actionHandler: ((_ text: String?) -> Void)? = nil) {
        
        let alert = UIAlertController(title: title, message: subtitle, preferredStyle: .alert)
        
        alert.addTextField { (textField:UITextField) in
            textField.placeholder = inputPlaceholder
            textField.keyboardType = inputKeyboardType
        }
        alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: { (action:UIAlertAction) in
            guard let textField =  alert.textFields?.first else {
                actionHandler?(nil)
                return
            }
            actionHandler?(textField.text)
        }))
        alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel, handler: {(action: UIAlertAction) in
            actionHandler?(nil)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func addTagToAsset(assetId: String, newTag: String, makeFolder: Bool){
        do {
            var allImagesTagsData = try [Images]()
            let assetId: String = assetId
            let newTag: String = newTag
            var allDirectories = try [Directory]()
            
            if let i = allDirectories.firstIndex(where: { $0.id == newTag }) {
                allDirectories[i].imageIDs.insert(assetId)
            }
            
            if let i = allImagesTagsData.firstIndex(where: { $0.id == assetId }) {
                allImagesTagsData[i].tags.insert(newTag)
            }else{
                let newAsset: Images = Images(id: assetId, tags: [newTag], isFavorite: false)
                allImagesTagsData.append(newAsset)
            }
            
            try allImagesTagsData.save()
//            addTagTextField.text = ""
            self.hideKeyboardWhenTappedAround()
//            self.collectionView.reloadData()
            
            //Mark: Recently Added Tags
            let defaults = UserDefaults.standard
            var recentlyAddedTags = defaults.object(forKey:"recentlyAddedTags") as? [String] ?? [String]()
            
            if recentlyAddedTags.count > 7 && !recentlyAddedTags.contains(newTag) {
                recentlyAddedTags.removeLast()
                recentlyAddedTags.insert(newTag, at: 0)
            }else if !recentlyAddedTags.contains(newTag){
                recentlyAddedTags.insert(newTag, at: 0)
            }
            defaults.set(recentlyAddedTags, forKey: "recentlyAddedTags")
            
            if(makeFolder){
                let isDirectoryExists = allDirectories.map{ $0.id }.contains(newTag) == true
                var directory: Directory
                let directoryIndex: Int
                
                if isDirectoryExists {
                    directoryIndex = allDirectories.firstIndex(where: { $0.id == newTag })!
                }else{
                    directory = Directory(id: newTag, imageIDs:[])
                    allDirectories.append(directory)
                    directoryIndex = allDirectories.count - 1
                }
                allImagesTagsData.forEach{
                    if($0.tags.contains(newTag)){
                        isDirectoryExists ? allDirectories[directoryIndex].imageIDs.insert($0.id) : allDirectories[directoryIndex].imageIDs.insert($0.id)
                    }
                }
                
            }
            try allDirectories.save()
            
            
        }catch{
            print("Could not add tag to asset: \(error)")
        }
    }
    
    func fetchLocalIdsFromCellPaths(selectedCells: NSMutableArray, fetchResult: PHFetchResult<PHAsset>!) -> Array<String> {
        let selectedCellPaths = selectedCells as NSArray as! [IndexPath]
        var selectedAssetsIds : [String] = []
        
        for cellPath in selectedCellPaths {
            let photoAsset = fetchResult.object(at: cellPath.item) as PHAsset
            selectedAssetsIds.append(photoAsset.localIdentifier)
        }
        
        return selectedAssetsIds
    }
    
    
}
