//
//  NoCountViewController.swift
//  County
//
//  Created by Adrian on 17.12.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit

class NoCountViewController: UIViewController {
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        view.backgroundColor = .white
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 100))
        label.text = Strings.noCounter
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textAlignment = .center
        
        label.center = view.center
        
        view.addSubview(label)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        _ = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { (_) in
            for subview in self.view.subviews {
                subview.removeFromSuperview()
            }
            
            self.viewDidAppear(true)
        })
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let counter = Counter(name: Strings.counter, count: 0, color: Color(from: 3))
        Counter.create(counter: counter)
        
        UIApplication.shared.keyWindow?.rootViewController = CountViewController()
    }
    
}
