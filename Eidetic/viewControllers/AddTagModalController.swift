//
//  AddTagModalController.swift
//  Eidetic
//
//  Created by user145467 on 11/30/18.
//  Copyright © 2018 user145467. All rights reserved.
//

import UIKit

class AddTagModalController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var addTagTextField: UITextField!
    @IBOutlet weak var addtagButton: UIButton!
    @IBOutlet weak var makeFolderCheckmark: UIButton!
    var delegate: AddTagModalControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addTagTextField.delegate = self
        addTagTextField.becomeFirstResponder()
        addtagButton.isEnabled = false
        
    }
    
    //Actions
    @IBAction func toggleCheckmark(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
    }
    @IBAction func closeModal(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func returnTagValue(_ sender: UIButton) {
        if let delegate = self.delegate {
            delegate.sendValue(value: addTagTextField.text!, makeFolder: makeFolderCheckmark.isSelected)
        }
        dismiss(animated: true, completion: nil)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        if newString.count > 0 {
            addtagButton.isEnabled = true
        }else{
            addtagButton.isEnabled = false
        }
        
        return true
    }
    
    


}
