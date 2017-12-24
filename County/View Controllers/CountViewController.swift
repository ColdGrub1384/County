//
//  ViewController.swift
//  County
//
//  Created by Adrian on 08.12.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit
import WatchConnectivity
import GoogleMobileAds

class CountViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, WCSessionDelegate, GADBannerViewDelegate {
    
    var countLabel: UILabel!
    var titleLabel: UILabel!
    var editTitle: UIButton!
    var addGesture: UISwipeGestureRecognizer!
    var substractGesture: UISwipeGestureRecognizer!
    var leftGesture: UISwipeGestureRecognizer!
    var rightGesture: UISwipeGestureRecognizer!
    var tabsCollectionView: UICollectionView!
    var interceptBannerClick: UIView!
    var adView: UIVisualEffectView!
    var counterView: UIView!
    var goBack: UIButton?
    var removeGroup: UIButton?
    var startAnimations = [Animation.recount, Animation.firstLaunch]
    var counter: Counter!
    var counters = [Counter]()
    
    // -------------------------------------------------------------------------
    // MARK: Static declarations
    // -------------------------------------------------------------------------
    
    static var shared = CountViewController()
    
    enum Animation {
        case recount
        case add
        case substract
        case firstLaunch
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
            counterVC.startAnimations = [.add]
        } else {
            counterVC.startAnimations = [.substract]
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
    // MARK: GADBannerViewDelegate
    // -------------------------------------------------------------------------
    
    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        print("Failed to receive ad: \(error.localizedDescription)")
    }
    
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        closeMaximizedAd()
    }
    
    // -------------------------------------------------------------------------
    // MARK: UIViewController
    // -------------------------------------------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if counter == nil {
            if let currentGroup = AppDelegate.shared.currentGroup {
                if AppDelegate.shared.currentCounter != -1 {
                    counter = Counter.counters(atDirectory: URL(string:currentGroup)!)[AppDelegate.shared.currentCounter]
                } else {
                    do {
                        counter = try Counter(file: URL(string:currentGroup)!)
                    } catch  {}
                }
            } else {
                counter = Counter.counters[AppDelegate.shared.currentCounter]
            }
            
        }
        
        if counter.isGroup {
            let childs = counter.childs
            counters = childs
        } else if let parent = counter.parent {
            let siblings = parent.childs
            counters = siblings
        } else {
            counters = Counter.counters
        }
        
        CountViewController.shared = self
        
        let orientation = UIApplication.shared.statusBarOrientation
        
        WCSession.default.delegate = self
        WCSession.default.activate()
        
        AppDelegate.shared.updateShortcutItems()
        
        // Helper to get center of space without tabs
        if orientation == .portrait || orientation == .portraitUpsideDown {
            counterView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height-140))
        } else {
            counterView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width-200, height: UIScreen.main.bounds.height))
        }
        counterView.backgroundColor = .clear
        view.addSubview(counterView)
        
        // Count label
        countLabel = UILabel(frame: CGRect(x :0, y: 0, width: counterView.frame.width, height: 160))
        countLabel.text = "\(counter.count)"
        countLabel.textColor = .white
        countLabel.font = UIFont.boldSystemFont(ofSize: 150)
        countLabel.textAlignment = .center
        countLabel.center = counterView.center
        
        // Counter title label
        titleLabel = UILabel(frame: CGRect(x: 0, y: 30, width: counterView.frame.width, height: 30))
        titleLabel.text = counter.name
        titleLabel.textColor = .white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 30)
        titleLabel.center.x = counterView.center.x
        titleLabel.textAlignment = .center
        
        // Edit counter title
        editTitle = UIButton(frame: CGRect(x: 0, y: 70, width: counterView.frame.width, height: 30))
        editTitle.setTitle("✎", for: .normal)
        editTitle.setAttributedTitle(NSAttributedString(string: "✎", attributes: [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 30), NSAttributedStringKey.foregroundColor : UIColor.white]), for: .normal)
        editTitle.tintColor = .white
        editTitle.center.x = counterView.center.x
        editTitle.addTarget(self, action: #selector(editCounterTitle), for: .touchUpInside)
        
        // Ad banner
        if AppDelegate.shared.adBanner == nil {
            AppDelegate.shared.adBanner = GADBannerView(adSize: kGADAdSizeBanner)
            AppDelegate.shared.adBanner.rootViewController = self
            AppDelegate.shared.adBanner.adUnitID = "ca-app-pub-9214899206650515/7728559868"
            AppDelegate.shared.adBanner.load(GADRequest())
        }
        AppDelegate.shared.adBanner.delegate = self
        AppDelegate.shared.adBanner.center.x = counterView.center.x
        // Portrait
        if orientation == .portrait || orientation == .portraitUpsideDown {
            AppDelegate.shared.adBanner.frame.origin.y = UIScreen.main.bounds.height-(140+AppDelegate.shared.adBanner.frame.size.height)
            
        } else { // Landscape
            AppDelegate.shared.adBanner.frame.origin.y = UIScreen.main.bounds.height-AppDelegate.shared.adBanner.frame.size.height
        }
        interceptBannerClick = UIView(frame: AppDelegate.shared.adBanner.frame)
        interceptBannerClick.backgroundColor = .clear
        interceptBannerClick.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showAd)))

        // Exit from group
        if counter.isGroup || counter.parent != nil {
            goBack = UIButton(frame: CGRect(x: 20, y: 90, width: 60, height: 60))
            goBack?.setImage(#imageLiteral(resourceName: "back"), for: .normal)
            goBack?.imageView?.tintColor = .white
            goBack?.imageView?.contentMode = .scaleAspectFill
            goBack?.addTarget(self, action: #selector(goBackFromGroup), for: .touchUpInside)
        }
        
        // Remove group
        if counter.isGroup || counter.parent != nil {
            removeGroup = UIButton(frame: CGRect(x: counterView.frame.width-80, y: 90, width: 60, height: 60))
            removeGroup?.setImage(#imageLiteral(resourceName: "close"), for: .normal)
            removeGroup?.imageView?.tintColor = .white
            removeGroup?.imageView?.contentMode = .scaleAspectFill
            removeGroup?.addTarget(self, action: #selector(remove), for: .touchUpInside)
        }
        
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
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 5
        if orientation == .portrait || orientation == .portraitUpsideDown { // Portrait
            // Display tabs at bottom
            layout.scrollDirection = .horizontal
            tabsCollectionView = UICollectionView(frame: CGRect(x: 0, y: UIScreen.main.bounds.size.height-140, width: UIScreen.main.bounds.size.width, height: 140), collectionViewLayout: layout)
        } else { // Landscape
            // Display tabs at right
            layout.scrollDirection = .vertical
            tabsCollectionView = UICollectionView(frame: CGRect(x: UIScreen.main.bounds.size.width-200, y: 0, width: 200, height: UIScreen.main.bounds.size.height), collectionViewLayout: layout)
        }
        tabsCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "collectionCell")
        tabsCollectionView.delegate = self
        tabsCollectionView.dataSource = self
        tabsCollectionView.backgroundColor = .clear
        
        // Add subviews
        if !counter.isGroup {
            view.addSubview(countLabel)
        }
        view.addSubview(titleLabel)
        view.addSubview(editTitle)
        view.addSubview(tabsCollectionView)
        view.addSubview(AppDelegate.shared.adBanner)
        view.addSubview(interceptBannerClick)
        if goBack != nil && removeGroup != nil {
            view.addSubview(goBack!)
            view.addSubview(removeGroup!)
        }
        
        if !counter.isGroup {
            view.addGestureRecognizer(addGesture)
            view.addGestureRecognizer(substractGesture)
            view.addGestureRecognizer(leftGesture)
            view.addGestureRecognizer(rightGesture)
        }
        
        view.backgroundColor = counter.color
        view.isUserInteractionEnabled = true
        
        // Start animation
        if startAnimations.contains(.firstLaunch) {
            
            let animView = UIView(frame: CGRect(x: 0, y: UIScreen.main.bounds.height, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
            animView.backgroundColor = view.backgroundColor
            view.insertSubview(animView, at: 0)
            
            view.backgroundColor = .white
            
            UIView.animate(withDuration: 0.5, animations: {
                animView.frame.origin.y = 0
            })
            
            _ = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { (_) in
                self.view.backgroundColor = animView.backgroundColor
                animView.removeFromSuperview()
            })
        }
        
        if startAnimations.contains(.recount) {
            AppDelegate.shared.animation(forLabel: countLabel, withCounter: counter, andDuration: 1)
        }
        
        if startAnimations.contains(.add) {
            animation(for: .add)
        }
        
        if startAnimations.contains(.substract) {
            animation(for: .substract)
        }
    }
    
    override func motionBegan(_ motion: UIEventSubtype, with event: UIEvent?) { // Reset counter to 0
        if motion == .motionShake {
            let alert = UIAlertController(title: Strings.ResetAlert.title, message: Strings.ResetAlert.message, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: Strings.no, style: .cancel, handler: nil))
            
            alert.addAction(UIAlertAction(title: Strings.yes, style: .destructive, handler: { (alert) in
                self.counter.count = 0
                self.tabsCollectionView.reloadData()
                self.sendToWatch()
            }))
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) { // Reload subviews when change device orientation
        _ = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { (_) in
            self.startAnimations = []
            for subview in self.view.subviews {
                subview.removeFromSuperview()
            }
            
            self.viewDidLoad()
        })
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // -------------------------------------------------------------------------
    // MARK: UICollectionViewDataSource
    // -------------------------------------------------------------------------
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if counter.isGroup || counter.parent != nil { // Hide the "Create group" cell if the counter is in a group or is a group
            return counters.count+1
        } else { 
            return counters.count+2
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell { // Tab
        
        let orientation = UIApplication.shared.statusBarOrientation
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionCell", for: indexPath as IndexPath)
        
        cell.backgroundColor = .clear

        // Count
        let countLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 95))
        countLabel.textAlignment = .center
        countLabel.center = cell.center
        countLabel.textColor = .white
        countLabel.font = UIFont.boldSystemFont(ofSize: 95)
        
        // Title
        let titleBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        let navItem = UINavigationItem(title: "")
        titleBar.setItems([navItem], animated: true)
        
        // Remove all subviews
        for view in cell.subviews {
            view.removeFromSuperview()
        }
        
        // Add subviews
        cell.addSubview(countLabel)
        cell.addSubview(titleBar)
        
        countLabel.center = cell.center
        
        if orientation == .portrait || orientation == .portraitUpsideDown {
            countLabel.frame.origin.y = 45
            countLabel.frame.origin.x -= CGFloat(205*indexPath.row)
        } else {
            countLabel.frame.origin.y -= CGFloat(145*indexPath.row)
        }
        
        if indexPath.row == counters.count { // Add new counter
            countLabel.text = "+"
            navItem.title = Strings.addNew
        } else if indexPath.row == counters.count+1 { // Add new group
            countLabel.text = "+"
            navItem.title = Strings.addGroup
        } else { // Open counter
            if indexPath.row == self.counter.row && !self.counter.isGroup {
                let closeItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(remove))
                titleBar.topItem?.setRightBarButton(closeItem, animated: true)
                
                countLabel.text = "\(counter.count)"
                titleBar.topItem?.title = counter.name
                cell.backgroundColor = counter.color
            } else {
                countLabel.text = "\(counters[indexPath.row].count)"
                titleBar.topItem?.title = counters[indexPath.row].name
                cell.backgroundColor = counters[indexPath.row].color
                
                if counters[indexPath.row].isGroup {
                    let folderView = UIImageView(frame: CGRect(x: 0, y: 40, width: cell.frame.width, height: cell.frame.height-40))
                    folderView.image = #imageLiteral(resourceName: "folder")
                    folderView.tintColor = .white
                    folderView.contentMode = .scaleAspectFit
                    cell.addSubview(folderView)
                    
                    if orientation == .portrait || orientation == .portraitUpsideDown {
                        countLabel.frame.origin.y += 7.5
                    } else {
                        countLabel.frame.origin.y += 30
                    }
                    
                    countLabel.font = UIFont.boldSystemFont(ofSize: 60)
                }
            }
        }
        
        
        return cell
    }

    
    // -------------------------------------------------------------------------
    // MARK: UICollectionViewDelegate
    // -------------------------------------------------------------------------
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row != counters.count && indexPath.row != counters.count+1 { // Open selected counter
            AppDelegate.shared.switchToCounter(counters[indexPath.row])
        } else if indexPath.row == counters.count { // Create new counter
            
            // Get number of counters
            var count = 0
            for counter in counters {
                if !counter.isGroup {
                    count += 1
                }
            }
            var newName = "\(Strings.counter) \(count+1)"
            if count == 0 {
                newName = Strings.counter
            }
            
            let newCounter = Counter(name: newName, count: 0, color: view.backgroundColor!)
            
            if let dir = counter.groupDirectory {
                Counter.create(counter: newCounter, inside: dir)
                newCounter.parent = counter
            } else if let dir = counter.parent?.groupDirectory {
                Counter.create(counter: newCounter, inside: dir)
                newCounter.parent = counter.parent
            } else {
                Counter.create(counter: newCounter)
            }

            AppDelegate.shared.switchToCounter(newCounter)
        } else { // Create group
            
            var dir = Counter.sharedDir
            if let dir_ = counter.parent?.groupDirectory {
                dir = dir_
            }
            
            do {
                // Get number of groups
                var count = 0
                for counter in counters {
                    if counter.isGroup {
                        count += 1
                    }
                }
                var newName = "\(Strings.group) \(count+1)"
                if count == 0 {
                    newName = Strings.group
                }
                
                try FileManager.default.createDirectory(atPath: dir.appendingPathComponent(newName).path, withIntermediateDirectories: false, attributes: nil)
                
                let newCounter = try Counter(file: dir.appendingPathComponent(newName))
                
                AppDelegate.shared.switchToCounter(newCounter)
                
            } catch _ {}
        }
    }
    
    // -------------------------------------------------------------------------
    // MARK: Actions
    // -------------------------------------------------------------------------
    
    @objc func remove() { // Remove counter
        
        if counter.parent != nil {
            counter.parent!.remove()
        } else {
            counter.remove()
        }
        
        AppDelegate.shared.currentCounter = 0
        AppDelegate.shared.currentGroup = nil
        if Counter.counters.count == 0 {
            AppDelegate.shared.updateShortcutItems()
            UIApplication.shared.keyWindow?.rootViewController = NoCountViewController()
        } else {
            let counterVC = CountViewController()
            counterVC.startAnimations = [.recount]
            
            UIApplication.shared.keyWindow?.rootViewController = counterVC
        }
        
    }
    
    @objc func editCounterTitle() { // Edit counter title
        let alert = UIAlertController(title: Strings.ChangeTitleAlert.title, message: Strings.ChangeTitleAlert.message(forCounter: counter.name), preferredStyle: .alert)
        
        alert.addTextField { (textfield) in
            textfield.placeholder = Strings.ChangeTitleAlert.placeholder
            textfield.text = self.counter.name
        }
        
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            let newName = alert.textFields![0].text!
            
            // Check if this name already exists
            var continue_ = true
            for counter in self.counters {
                if counter.name == newName {
                    
                    let alert = UIAlertController(title: Strings.CannotRenameCounter.title, message: Strings.CannotRenameCounter.message(forCounter: counter.name), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    
                    continue_ = false
                    break
                }
            }
            
            if newName == "" { // Continue only if the name is not empty
                continue_ = false
            }
            
            if !self.counter.isGroup { // Rename counter
                // Apply changes
                if continue_ {
                    self.counter.name = newName
                    self.titleLabel.text = self.counter.name
                    self.tabsCollectionView.reloadData()
                    self.sendToWatch()
                    AppDelegate.shared.updateShortcutItems()
                }
            } else if let dir = self.counter.groupDirectory { // Rename group
                let newDir = dir.deletingLastPathComponent().appendingPathComponent(newName)
                try? FileManager.default.moveItem(at: dir, to: newDir)
                
                AppDelegate.shared.updateShortcutItems()
                
                AppDelegate.shared.currentGroup = newDir.absoluteString
                
                let countVC = CountViewController()
                countVC.startAnimations = []
                UIApplication.shared.keyWindow?.rootViewController = countVC
            }
        }))
        
        alert.addAction(UIAlertAction(title: Strings.cancel, style: .cancel, handler: nil))
        
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
        AppDelegate.shared.updateShortcutItems()
    }
    
    @objc func substract(_ sender: UISwipeGestureRecognizer) { // Substract
        counter.count -= 1
        tabsCollectionView.reloadData()
        animation(for: .substract)
        sendToWatch()
        AppDelegate.shared.updateShortcutItems()
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
    
    @objc func showAd() { // Maximize ad
        
        adView = UIVisualEffectView(frame: view.frame)
        adView.effect = UIBlurEffect(style: .light)
        
        view.addSubview(adView)
        
        let navBar = UINavigationBar(frame: CGRect(x: AppDelegate.shared.adBanner.frame.origin.x, y: AppDelegate.shared.adBanner.frame.origin.y-40, width: AppDelegate.shared.adBanner.frame.width, height: 40))
        let topItem = UINavigationItem(title: Strings.sponsored)
        
        let close = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeMaximizedAd))
        topItem.rightBarButtonItem = close
        navBar.setItems([topItem], animated: true)
        
        AppDelegate.shared.adBanner.removeFromSuperview()
        adView.contentView.addSubview(AppDelegate.shared.adBanner)
        adView.contentView.addSubview(navBar)
    }

    @objc func closeMaximizedAd() { // Close maximized ad
        AppDelegate.shared.adBanner.removeFromSuperview()
        adView.removeFromSuperview()
        view.addSubview(AppDelegate.shared.adBanner)
        view.bringSubview(toFront: interceptBannerClick)
    }
    
    @objc func goBackFromGroup() { // Go back and leave group
        AppDelegate.shared.currentCounter = 0
        AppDelegate.shared.currentGroup = nil
        
        if Counter.counters.count > 1 {
            let countVC = CountViewController()
            countVC.startAnimations = [.recount]
            UIApplication.shared.keyWindow?.rootViewController = countVC
        } else { // There is no other counter than the current group
            UIApplication.shared.keyWindow?.rootViewController = NoCountViewController()
        }
        
    }
}

