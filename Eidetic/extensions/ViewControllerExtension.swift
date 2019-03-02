//
//  ViewController.swift
//  Eidetic
//
//  Created by user145467 on 11/30/18.
//  Copyright © 2018 user145467. All rights reserved.
//

import Foundation
import UIKit
import Photos
import PhotosUI

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.recentSearches.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:UITableViewCell = self.recentSearchesTableView.dequeueReusableCell(withIdentifier: "RecentSearchCell") as UITableViewCell!
        
        // set the text from the data model
        cell.textLabel?.text = self.recentSearches[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let searchText = self.recentSearches[indexPath.row]
        searchBar.text = searchText
        searchForTag(searchText: searchText)
        recentSearchesTableView.isHidden = true
        print("You tapped cell number \(indexPath.row).")
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Suggestions"
    }
    
    
    //MARK: Recent Search Table View
    
    func restoreDefaultsOnEmptySearch() {
        do{
            let allPhotosOptions = PHFetchOptions()
            allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            if(directoryName == nil){
                fetchResult = PHAsset.fetchAssets(with: allPhotosOptions)
            }else{
                let allDirectories = try [Directory]()
                let imageIds = allDirectories.first{$0.id == directoryName}?.imageIDs
                fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: Array(imageIds!), options: allPhotosOptions)
            }
            collectionView.reloadData()
        }catch{
            print("Search Error \(error)")
        }
    }
    
    func searchForTag(searchText: String){
        do{
            var allImages = try [Images]()
            if directoryName != nil{
                let allDirectories = try [Directory]()
                let imageIds = allDirectories.first{$0.id == directoryName}?.imageIDs
                allImages = allImages.filter{(image: Images) -> Bool in
                    return imageIds!.contains(image.id)
                }
            }
            
            var filteredImages: [Images]
            filteredImages = allImages.filter { (image: Images) -> Bool in
                for imageTag in image.tags{
                    if imageTag.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil{
                        return true
                    }
                }
                return false
            }
            var filteredTags: [String] = Array()
            allImages.forEach { (image: Images) -> Void in
                for imageTag in image.tags{
                    if imageTag.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil{
                        filteredTags.append(imageTag)
                    }
                }
            }
            recentSearches = filteredTags
            recentSearchesTableView.reloadData()
            
            if filteredImages.count == 0 {
                fetchResult = nil
            }else{
                let imageIds = filteredImages.map({$0.id})
                fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: imageIds, options: nil)
            }
            collectionView.reloadData()
        }catch{
            print("Search error: \(error)")
        }
    }
    
    func clearSelections(allowsMultipleSelection: Bool)  {
        collectionView.allowsMultipleSelection = allowsMultipleSelection
        let selectedCells: NSArray = _selectedCells
        for cellPath in selectedCells {
            guard let selectedCell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: PhotoCell.self), for: cellPath as! IndexPath) as? PhotoCell
                else { fatalError("unexpected cell in collection view") }
            selectedCell.isSelected = false
        }
        _selectedCells.removeAllObjects()
        
        if allowsMultipleSelection {
            cameraButton.isEnabled = false
            selectButton.title = "Cancel"
            navigationController?.isToolbarHidden = false
            self.navigationItem.title = "Select Items"
            searchBar.isUserInteractionEnabled = false
            searchBar.alpha = 0.75
            searchBar.searchBarStyle = .minimal
            searchBar.isTranslucent = false
            addTagButton.isEnabled = _selectedCells.count > 0 ? true : false
        }else{
            cameraButton.isEnabled = true
            selectButton.title = "Select"
            navigationController?.isToolbarHidden = true
            self.navigationItem.title = directoryName
            searchBar.isUserInteractionEnabled = true
            searchBar.alpha = 1
            searchBar.searchBarStyle = .default
            searchBar.isTranslucent = true
            
        }
        collectionView.reloadData()
    }
}
