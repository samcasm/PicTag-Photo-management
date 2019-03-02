//
//  TagsCollection.swift
//  Eidetic
//
//  Created by user147964 on 1/27/19.
//  Copyright © 2019 user145467. All rights reserved.
//

import UIKit

class TagsCollection: UICollectionView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout{

    let reuseIdentifier = "TagCell" // also enter this string as the cell identifier in the storyboard
    var arrayOfTags: [String] = Array()
    var phassetID : String!
    
    func displayTags(){
        do{
            let assetId = phassetID
            let allImagesTagsData = try [Images]()
            let assetIndex = allImagesTagsData.firstIndex(where: { $0.id == assetId })
        
            if assetIndex != nil{
                arrayOfTags = Array(allImagesTagsData[assetIndex!].tags)
            }
        }catch{
            print("Tag Display View Error: \(error)")
        }
    }
    
    func setAssetID(assetID: String){
        phassetID = assetID
    }
    
    override func awakeFromNib() {
        self.dataSource = self
        self.delegate = self
        
    }
    
    // MARK: - UICollectionViewDataSource protocol
    
    // tell the collection view how many cells to make
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        displayTags()
        return arrayOfTags.count
    }
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
     
        
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! TagCell
        
        // Use the outlet in our custom class to get a reference to the UILabel in the cell
        cell.myLabel.text = arrayOfTags[indexPath.item]
        cell.deleteTagButton.addTarget(self, action: #selector(self.deleteTag(sender:)), for: .touchUpInside)
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegate protocol
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // handle tap events
        print("You selected cell #\(indexPath.item)!")
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // get a reference to our storyboard cell
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! TagCell
//        return cell.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        
        let size: CGSize = arrayOfTags[indexPath.row].size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0)])
        return CGSize(width: size.width + 65.0, height: 45)
    }
    
    @objc func deleteTag(sender: UIButton){
        do{
            guard let cell = sender.superview?.superview as? TagCell else {
                return // or fatalError() or whatever
            }
            guard let tagsCollectionView = sender.superview?.superview?.superview as? TagsCollection else {
                return // or fatalError() or whatever
            }
            let assetId = phassetID
            var allImagesTagsData = try [Images]()
            var allDirectories = try [Directory]()
            
            if let i = allImagesTagsData.firstIndex(where: { $0.id == assetId }) {
                allImagesTagsData[i].tags.remove(cell.myLabel.text ?? "")
                try allImagesTagsData.save()
            }

            if let i = allDirectories.firstIndex(where: { $0.id == cell.myLabel.text }) {
                allDirectories[i].imageIDs.remove(assetId ?? "")
                if allDirectories[i].imageIDs.count == 0 {
                    allDirectories.remove(at: i)
                }
                try allDirectories.save()
            }
            tagsCollectionView.reloadData()
        }catch{
            print("Delete Tag Error: \(error)")
        }
    }
}

