//
//  DetailedColleviewViewCellCollectionViewCell.swift
//  Eidetic
//
//  Created by user147964 on 1/27/19.
//  Copyright © 2019 user145467. All rights reserved.
//

import UIKit
import UICollectionViewLeftAlignedLayout

class DetailedCollectionViewCell: UICollectionViewCell, UITextFieldDelegate{
    

    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var addTagButton: UIButton!
    @IBOutlet weak var addTagTextField: UITextField!
    @IBOutlet weak var makeFolderCheckBox: UIButton!
    
    @IBOutlet weak var addTagStackView: UIStackView!
    @IBOutlet weak var tagsCollectionView: TagsCollection!
    
    
    override func awakeFromNib() {
        addTagButton.addTarget(self, action: #selector(self.addTag), for: .touchUpInside)
        addTagTextField.delegate = self
        
        let myColor : UIColor = UIColor( red: 128.0/255.0, green: 128.0/255.0, blue:128.0/255.0, alpha: 1.0 )
        addTagTextField.layer.borderWidth = 2
        addTagTextField.layer.borderColor = myColor.cgColor
        addTagTextField.layer.cornerRadius = 5.0
        self.tagsCollectionView.collectionViewLayout = UICollectionViewLeftAlignedLayout()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let maxLength = 17
        let currentString: NSString = textField.text! as NSString
        let newString: NSString =
            currentString.replacingCharacters(in: range, with: string) as NSString
        return newString.length <= maxLength
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        addTagToCollection()
        textField.resignFirstResponder()
        return true
    }

    @IBAction func folderToggle(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
    }
    
    
    var assetIdentifier: String! {
        didSet {
            tagsCollectionView.setAssetID(assetID: assetIdentifier)
        }
    }
    
    var assetImage: UIImage! {
        didSet {
            imageView.image = assetImage
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        tagsCollectionView.isHidden = true
    }
    
    func addTagToCollection(){
        if addTagTextField.text?.hasAlphanumeric == true {
            do {
                var allImagesTagsData = try [Images]()
                let assetId: String = assetIdentifier
                let newTag: String = String(addTagTextField.text!)
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
                addTagTextField.text = ""
                
                //Mark: Recently Added Tags
                let defaults = UserDefaults.standard
                var recentlyAddedTags = defaults.object(forKey:"recentlyAddedTags") as? [String] ?? [String]()
            
                
                if recentlyAddedTags.count > 7 && !recentlyAddedTags.contains(newTag){
                    recentlyAddedTags.removeLast()
                    recentlyAddedTags.insert(newTag, at: 0)
                }else if !recentlyAddedTags.contains(newTag){
                    recentlyAddedTags.insert(newTag, at: 0)
                }
                defaults.set(recentlyAddedTags, forKey: "recentlyAddedTags")
                
                if(makeFolderCheckBox.isSelected){
                    
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
                tagsCollectionView.isHidden = false
                makeFolderCheckBox.isSelected = false
                tagsCollectionView.reloadData()
                addTagTextField.resignFirstResponder()
            }catch{
                print("Could not add tag to asset: \(error)")
            }
        }
    }
    
    @objc func addTag(sender: UIButton){
        addTagToCollection()
    }
}
