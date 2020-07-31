//
//  SecondViewController.swift
//  Example
//
//  Created by WHB on 7/31/20.
//  Copyright © 2020 WHB. All rights reserved.
//

import UIKit

class SecondViewController: UIViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
}
