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
    @IBOutlet var recorderButton: UIButton!
    @IBOutlet var mappingButton: UIButton!
    @IBOutlet var titleView1: UIView!
    @IBOutlet var titleView2: UIView!
    @IBOutlet var gradientView: UIView!
    @IBOutlet var gradientView2: UIView!
    @IBOutlet var textView: UITextView!
    @IBOutlet var indianTitle: UILabel!
    @IBOutlet var rockTitle: UILabel!
    
    override func viewDidLoad() {
        setUpTitle()
        entryButton.layer.cornerRadius = 30
        entryButton.clipsToBounds = true
        titleView1.layer.cornerRadius = 40
        titleView1.clipsToBounds = true
        titleView2.layer.cornerRadius = 40
        titleView2.clipsToBounds = true
        textView.layer.shadowColor = UIColor.black.cgColor;
        textView.layer.shadowOffset = CGSize(width: 1.0, height: 1.0)
        textView.layer.shadowOpacity = 1.0;
        textView.layer.shadowRadius = 1.5;
    }
    
    func setUpTitle() {
        indianTitle.frame = gradientView.bounds
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor.systemTeal.cgColor, UIColor.systemPurple.cgColor]
        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradient.frame = titleView1.bounds
        gradientView.layer.addSublayer(gradient)
        gradientView.addSubview(indianTitle)
        gradientView.mask = indianTitle
        
        rockTitle.frame = gradientView2.bounds
        let gradient2 = CAGradientLayer()
        gradient2.colors = [UIColor.systemTeal.cgColor, UIColor.systemPurple.cgColor]
        gradient2.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradient2.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradient2.frame = titleView2.bounds
        gradientView2.layer.addSublayer(gradient2)
        gradientView2.addSubview(rockTitle)
        gradientView2.mask = rockTitle
    }
    
    @IBAction func viewerButtonPressed() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "Viewer") as! ViewController
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func recorderButtonPressed() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "Recorder") as! RecorderVC
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func mappingButtonPressed() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "Mapper") as! MappingVC
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }
}
