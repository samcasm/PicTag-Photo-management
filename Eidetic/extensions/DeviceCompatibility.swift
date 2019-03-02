//
//  DeviceCompatibility.swift
//  Eidetic
//
//  Created by user147964 on 2/3/19.
//  Copyright © 2019 user145467. All rights reserved.
//

import UIKit

extension ViewController {
    
    func setRecentSearchesTable() -> CGRect{
        if UIDevice().userInterfaceIdiom == .phone {
            switch UIScreen.main.nativeBounds.height {
            case 1136:
                print("iPhone 5 or 5S or 5C")
                return CGRect(x: 0, y: searchBar.frame.maxY, width: view.frame.width, height: view.frame.height)
                
            case 1334:
                print("iPhone 6/6S/7/8")
                
            case 1920, 2208:
                print("iPhone 6+/6S+/7+/8+")
                
            case 2436:
                print("iPhone X, XS")
                return CGRect(x: 0, y: CGFloat(integerLiteral: 144) , width: view.frame.width, height: view.frame.height)
                
            case 2688:
                print("iPhone XS Max")
                return CGRect(x: 0, y: CGFloat(integerLiteral: 144) , width: view.frame.width, height: view.frame.height)
                
            case 1792:
                print("iPhone XR")
                return CGRect(x: 0, y: CGFloat(integerLiteral: 144) , width: view.frame.width, height: view.frame.height)
                
            default:
                print("Unknown")
                return CGRect(x: 0, y: searchBar.frame.maxY, width: view.frame.width, height: view.frame.height)
            }
        }
        return CGRect(x: 0, y: searchBar.frame.maxY, width: view.frame.width, height: view.frame.height)
    }
}
