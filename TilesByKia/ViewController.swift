//
//  ViewController.swift
//  TilesByKia
//
//  Created by Michael Kampouris on 5/7/22.
//

import UIKit
import FirebaseAuth

class ViewController: UIViewController {
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let email = "mkampouris@gmail.com"
        let password = "Orange88"
        
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                print(error.localizedDescription)
            } else {
                self.performSegue(withIdentifier: "toListViewVC", sender: Any?.self)
            }
        }
    }

}

