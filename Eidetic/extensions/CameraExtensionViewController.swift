//
//  CameraViewController.swift
//  Eidetic
//
//  Created by user147964 on 12/23/18.
//  Copyright © 2018 user145467. All rights reserved.
//

import UIKit
import Photos

extension ViewController : UINavigationControllerDelegate, UIImagePickerControllerDelegate  {
    
    enum ImageSource {
        case photoLibrary
        case camera
    }
    
    func selectImageFrom(_ source: ImageSource){
        imagePicker =  UIImagePickerController()
        imagePicker.delegate = self
        switch source {
        case .camera:
            imagePicker.sourceType = .camera
        case .photoLibrary:
            imagePicker.sourceType = .photoLibrary
        }
        present(imagePicker, animated: true, completion: nil)
    }
    
    //MARK: - Add image to Library
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            showAlertWith(title: "Save error", message: error.localizedDescription)
        } else {
            showAlertWith(title: "Saved!", message: "Your image has been saved to your photos.")
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.fetchLimit = 1
            
            let assetsArray = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            if (assetsArray.firstObject != nil)
            {
                cameraImageAsset = fetchResult.firstObject
            }else{
                cameraImageAsset = nil
            }
            
            imagePicker.dismiss(animated: true, completion: nil)
            
            self.performSegue(withIdentifier: "cameraPhotoDetailsSegue", sender: self)
        }
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let selectedImage = info[.originalImage] as? UIImage else {
            print("Image not found!")
            return
        }
        if picker.sourceType == UIImagePickerController.SourceType.camera{
            UIImageWriteToSavedPhotosAlbum(selectedImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    
    
}

