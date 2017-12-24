//
//  NoCountViewController.swift
//  County
//
//  Created by Adrian on 17.12.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit

class NoCountViewController: CountViewController {
    
    override func viewDidLoad() {
        
        // Hide animation
        startAnimations = []
        
        // Create counter to prevent the app from crashing
        counter = Counter(name: "", count: 0, color: Color(from: 3))
        
        super.viewDidLoad() // Setup the ViewController
        
        
        // Hide counter interface
        countLabel.removeFromSuperview()
        editTitle.removeFromSuperview()
        titleLabel.removeFromSuperview()
        view.gestureRecognizers = nil
    }
    
}
