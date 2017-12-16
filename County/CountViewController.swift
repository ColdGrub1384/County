//
//  ViewController.swift
//  County
//
//  Created by Adrian on 08.12.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit
import WatchConnectivity

class CountViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, WCSessionDelegate {
    
    var countLabel: UILabel!
    var titleLabel: UILabel!
    var editTitle: UIButton!
    var addGesture: UISwipeGestureRecognizer!
    var substractGesture: UISwipeGestureRecognizer!
    var leftGesture: UISwipeGestureRecognizer!
    var rightGesture: UISwipeGestureRecognizer!
    var tabsCollectionView: UICollectionView!
    var startAnimation = Animation.recount
    var counter = Counter.counters[AppDelegate.shared.currentCounter]
    
    // -------------------------------------------------------------------------
    // MARK: Static declarations
    // -------------------------------------------------------------------------
    
    static var shared = CountViewController()
    
    enum Animation {
        case recount
        case add
        case substract
        case none
    }
    
    // -------------------------------------------------------------------------
    // MARK: Watch Connectivity
    // -------------------------------------------------------------------------
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Activation completed with state: \(activationState.rawValue)")
        if let error = error {
            print("Error activating session: \(error.localizedDescription)")
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("Session become inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) { // Received data from Watch
        
        print("RECEIVED COUNTER!!")
        
        // Parse data
        guard let name = message["name"] as? String else { return }
        guard let count = message["count"] as? Int else { return }
        guard let color = message["color"] as? Int else { return }
        
        print(message)
        
        // Create counter with given data
        let counter = Counter(name: name, count: count, color: Color(from: color))
        Counter.create(counter: counter)
        let counterVC = CountViewController()
        counterVC.counter = counter
        
        if self.counter.count < counter.count {
            counterVC.startAnimation = .add
        } else {
            counterVC.startAnimation = .substract
        }
        
        // Open counter
        DispatchQueue.main.async {
            UIApplication.shared.keyWindow?.rootViewController = counterVC
        }
    }
    
    func sendToWatch() { // Send data to Watch
        DispatchQueue.global(qos: .background).async {
            if WCSession.isSupported() && WCSession.default.isWatchAppInstalled {
                print("Send counter")
                if WCSession.default.isReachable { // If Watch app is opened, send direct message
                    WCSession.default.sendMessage(["name":self.counter.name,"count":self.counter.count,"color":Identifier(forColor: self.counter.color)], replyHandler: nil, errorHandler: nil)
                } else {
                    do {
                        print("Send context instead of message")
                        try WCSession.default.updateApplicationContext(["name":self.counter.name,"count":self.counter.count,"color":Identifier(forColor: self.counter.color)])
                    } catch let error {
                        print("ERROR SENDING CONTEXT: \(error.localizedDescription)")
                    }
                }
                
            } else {
                print("Watch app is not installed")
            }
        }
    }
    
    // -------------------------------------------------------------------------
    // MARK: UIViewController
    // -------------------------------------------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        CountViewController.shared = self
        
        WCSession.default.delegate = self
        WCSession.default.activate()
        
        // Count label
        countLabel = UILabel(frame: CGRect(x :0, y: 0, width: UIScreen.main.bounds.size.width, height: 200))
        countLabel.text = "\(counter.count)"
        countLabel.textColor = .white
        countLabel.font = UIFont.boldSystemFont(ofSize: 150)
        countLabel.center = view.center
        countLabel.textAlignment = .center
        
        
        // Counter title label
        titleLabel = UILabel(frame: CGRect(x: 0, y: 30, width: UIScreen.main.bounds.size.width, height: 30))
        titleLabel.text = counter.name
        titleLabel.textColor = .white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 30)
        titleLabel.center.x = view.center.x
        titleLabel.textAlignment = .center
        
        // Edit counter title
        editTitle = UIButton(frame: CGRect(x: 0, y: 70, width: UIScreen.main.bounds.size.width, height: 30))
        editTitle.setTitle("✎", for: .normal)
        editTitle.setAttributedTitle(NSAttributedString(string: "✎", attributes: [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 30), NSAttributedStringKey.foregroundColor : UIColor.white]), for: .normal)
        editTitle.tintColor = .white
        editTitle.center.x = view.center.x
        editTitle.addTarget(self, action: #selector(editCounterTitle), for: .touchUpInside)
        
        // Gestures
        
        // Add
        addGesture = UISwipeGestureRecognizer(target: self, action: #selector(add(_:)))
        addGesture.direction = .up
        
        // Substract
        substractGesture = UISwipeGestureRecognizer(target: self, action: #selector(substract(_:)))
        substractGesture.direction = .down
        
        // Change color
        leftGesture = UISwipeGestureRecognizer(target: self, action: #selector(changeColor(_:)))
        leftGesture.direction = .left
        rightGesture = UISwipeGestureRecognizer(target: self, action: #selector(changeColor(_:)))
        rightGesture.direction = .right
        
        // Tabs
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 200, height: 140)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 5
        tabsCollectionView = UICollectionView(frame: CGRect(x: 0, y: UIScreen.main.bounds.size.height-140, width: UIScreen.main.bounds.size.width, height: 140), collectionViewLayout: layout)
        tabsCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "collectionCell")
        tabsCollectionView.delegate = self
        tabsCollectionView.dataSource = self
        tabsCollectionView.backgroundColor = .clear
        
        // Add subviews
        view.addSubview(countLabel)
        view.addSubview(titleLabel)
        view.addSubview(editTitle)
        view.addSubview(tabsCollectionView)
        view.addGestureRecognizer(addGesture)
        view.addGestureRecognizer(substractGesture)
        view.addGestureRecognizer(leftGesture)
        view.addGestureRecognizer(rightGesture)
        view.backgroundColor = counter.color
        view.isUserInteractionEnabled = true
        
        // Start animation
        if startAnimation == .recount {
            AppDelegate.shared.animation(forLabel: countLabel, withCounter: counter, andDuration: 1)
        }
        
        if startAnimation == .add {
            animation(for: .add)
        }
        
        if startAnimation == .substract {
            animation(for: .substract)
        }
    }
    
    override func motionBegan(_ motion: UIEventSubtype, with event: UIEvent?) { // Reset counter to 0
        if motion == .motionShake {
            let alert = UIAlertController(title: "Reset?", message: "Do you want to reset to 0 your count?", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
            
            alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { (alert) in
                self.counter.count = 0
                self.tabsCollectionView.reloadData()
                self.sendToWatch()
            }))
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // -------------------------------------------------------------------------
    // MARK: UICollectionViewDataSource
    // -------------------------------------------------------------------------
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Counter.counters.count+1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell { // Tab
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionCell", for: indexPath as IndexPath)
        
        cell.backgroundColor = .clear
        

        // Count
        let countLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 95))
        countLabel.textAlignment = .center
        countLabel.center = cell.center
        countLabel.text = "+"
        countLabel.textColor = .white
        countLabel.font = UIFont.boldSystemFont(ofSize: 95)
        
        // Title
        let titleBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        let navItem = UINavigationItem(title: "Add new")
        titleBar.setItems([navItem], animated: true)
        
        // Remove all subviews
        for view in cell.subviews {
            view.removeFromSuperview()
        }
        
        // Add subviews
        cell.addSubview(countLabel)
        cell.addSubview(titleBar)
        countLabel.frame.origin.y = 45
        countLabel.frame.origin.x -= CGFloat(205*indexPath.row)
        
        // If the tab is not the last, put content of the counter, else, the tab is used to add a new counter
        if indexPath.row != collectionView.numberOfItems(inSection: 0)-1 {
            cell.backgroundColor = Counter.counters[indexPath.row].color
            countLabel.text = "\(Counter.counters[indexPath.row].count)"
            titleBar.topItem?.title = Counter.counters[indexPath.row].name
            
            if indexPath.row == self.counter.row {
                let closeItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(remove))
                titleBar.topItem?.setRightBarButton(closeItem, animated: true)
            }
        }
        
        return cell
    }

    
    // -------------------------------------------------------------------------
    // MARK: UICollectionViewDelegate
    // -------------------------------------------------------------------------
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row != collectionView.numberOfItems(inSection: 0)-1 { // Open selected counter
            AppDelegate.shared.switchToCounter(Counter.counters[indexPath.row])
        } else { // Create new counter
            let newCounter = Counter(name: "Counter \(indexPath.row+1)", count: 0, color: view.backgroundColor!)
            Counter.create(counter: newCounter)
            AppDelegate.shared.switchToCounter(newCounter)
        }
    }
    
    // -------------------------------------------------------------------------
    // MARK: Actions
    // -------------------------------------------------------------------------
    
    @objc func remove() { // Remove counter
        counter.remove()
        AppDelegate.shared.currentCounter = 0
        if Counter.counters.count == 0 {
            UIApplication.shared.keyWindow?.rootViewController = nil
        } else {
            UIApplication.shared.keyWindow?.rootViewController = CountViewController()
        }
        
    }
    
    @objc func editCounterTitle() { // Edit counter title
        let alert = UIAlertController(title: "Change title", message: "Type new title for \(counter.name)", preferredStyle: .alert)
        
        alert.addTextField { (textfield) in
            textfield.placeholder = "New title"
            textfield.text = self.counter.name
        }
        
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            self.counter.name = alert.textFields![0].text!
            self.titleLabel.text = self.counter.name
            self.tabsCollectionView.reloadData()
            self.sendToWatch()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func animation(for action: Counter.Action, firstTime: Bool = true) {
        
        UIView.animate(withDuration: 0.5) {
            var newSize = self.countLabel.font.pointSize
            
            if action == .add {
                newSize = newSize*1.5
            } else {
                newSize = newSize/1.5
            }
            
            self.countLabel.font = UIFont.boldSystemFont(ofSize: newSize)
        }
        
        _ = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false, block: { (_) in
            if firstTime {
                if action == .add {
                    self.animation(for: .substract, firstTime: false)
                } else {
                    self.animation(for: .add, firstTime: false)
                }
            }
        })
    }
    
    @objc func add(_ sender: UISwipeGestureRecognizer) { // Add
        counter.count += 1
        tabsCollectionView.reloadData()
        animation(for: .add)
        sendToWatch()
    }
    
    @objc func substract(_ sender: UISwipeGestureRecognizer) { // Substract
        counter.count -= 1
        tabsCollectionView.reloadData()
        animation(for: .substract)
        sendToWatch()
    }
    
    @objc func changeColor(_ sender: UISwipeGestureRecognizer) { // Change counter color
        let id = Identifier(forColor: counter.color)
        var newColor = UIColor.clear
        var change = true
        
        if sender.direction == .left {
            newColor = Color(from: id-1)
            change = ((id-1) >= 0)
        } else if sender.direction == .right {
            newColor = Color(from: id+1)
            change = ((id+1) <= 6)
        }

        if change {
            counter.color = newColor
            tabsCollectionView.reloadData()
            sendToWatch()
            UIView.animate(withDuration: 0.5, animations: {
                self.view.backgroundColor = newColor
            })
        }
    }
    
    
}

