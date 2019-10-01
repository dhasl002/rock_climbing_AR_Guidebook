//
//  EntryViewController.swift
//  ClientApp
//
//  Created by Devin Haslam on 9/30/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import UIKit
import Foundation

class EntryViewController: UIViewController {
    @IBOutlet var mainView: UIView!
    @IBOutlet var entryButton: UIButton!
    
    override func viewDidLoad() {
        entryButton.layer.cornerRadius = 30
        entryButton.clipsToBounds = true
    }
}
