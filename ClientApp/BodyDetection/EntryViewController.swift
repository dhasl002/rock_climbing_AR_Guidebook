//
//  EntryViewController.swift
//  ClientApp
//
//  Created by Devin Haslam on 9/30/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import UIKit
import Foundation
//-86

class EntryViewController: UIViewController {
    @IBOutlet var mainView: UIView!
    @IBOutlet var entryButton: UIButton!
    @IBOutlet var titleView1: UIView!
    @IBOutlet var titleView2: UIView!
    @IBOutlet var gradientView: UIView!
    @IBOutlet var textView: UITextView!
    @IBOutlet var indianTitle: UILabel!
    
    override func viewDidLoad() {
        setUpTitle()
        titleView1.layer.cornerRadius = 40
        titleView1.clipsToBounds = true
        titleView2.layer.cornerRadius = 40
        titleView2.clipsToBounds = true
        entryButton.layer.cornerRadius = 30
        entryButton.clipsToBounds = true
        textView.layer.shadowColor = UIColor.black.cgColor;
        textView.layer.shadowOffset = CGSize(width: 1.0, height: 1.0)
        textView.layer.shadowOpacity = 0.5;
        textView.layer.shadowRadius = 1.0;
    }
    
    func setUpTitle() {
        indianTitle.frame = titleView1.bounds
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor.systemTeal.cgColor, UIColor.purple.cgColor]
        gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradient.frame = titleView1.bounds
        titleView1.layer.addSublayer(gradient)
        titleView1.addSubview(indianTitle)
        titleView1.mask = indianTitle
    }
    
    @IBAction func buttonPressed() {
        self.performSegue(withIdentifier: "enterAR", sender: self)
    }
    
    
}
