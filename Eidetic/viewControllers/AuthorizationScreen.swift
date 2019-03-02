//
//  AuthorizationCheck.swift
//  Eidetic
//
//  Created by user147964 on 2/17/19.
//  Copyright © 2019 user145467. All rights reserved.
//

import Foundation
import Photos

class AuthorizationScreen: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized:
            print("authorized")
            self.performSegue(withIdentifier: "accessGrantedSegue", sender: self)
            
        case .denied:
            print("denied") // it is denied
            
        case .notDetermined:
            print("notDetermined")
            PHPhotoLibrary.requestAuthorization({status in
                if status == .authorized{
                    self.performSegue(withIdentifier: "accessGrantedSegue", sender: self)
                }else if status == .denied{
                    print("denied")
                }
            })
            
        case .restricted:
            print("restricted")
            
        }
    }
    
    @IBAction func settingsSegue(_ sender: UIButton) {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                print("Settings opened: \(success)") // Prints true
            })
        }
    }
    
}
