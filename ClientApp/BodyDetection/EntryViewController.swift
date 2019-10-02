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
    @IBOutlet var titleView1: UIView!
    @IBOutlet var titleView2: UIView!
    
    override func viewDidLoad() {
        entryButton.layer.cornerRadius = 30
        entryButton.clipsToBounds = true
        titleView1.layer.cornerRadius = 40
        titleView1.clipsToBounds = true
        titleView2.layer.cornerRadius = 40
        titleView2.clipsToBounds = true
    }
    
    @IBAction func buttonPressed() {
        let vc = ViewController()
    }
}
