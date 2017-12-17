 //
//  AppDelegate.swift
//  County
//
//  Created by Adrian on 08.12.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit
import UserNotifications
import Firebase
 
@UIApplicationMain
 class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    static let shared = AppDelegate()
    
    var currentCounter: Int { // Current selected counter
        get {
            let returnValue = Counter.userDefaults.integer(forKey: "currentCounter")
            return returnValue
        }
        
        set {
            Counter.userDefaults.set(newValue, forKey: "currentCounter")
        }
    }
    
    func switchToCounter(_ counter: Counter) { // Open a CountViewController from a counter
        currentCounter = counter.row
        
        let counterVC = CountViewController()
        
        counterVC.startAnimations = [.recount]
        
        UIApplication.shared.keyWindow?.rootViewController = counterVC
        UIApplication.shared.applicationIconBadgeNumber = counter.count
        
        counterVC.sendToWatch()
    }
    
    func animation(forLabel countLabel: UILabel, withCounter counter: Counter, andDuration duration: Double) { // Play recount animation for a label
        var count = 0
        var interval = duration/Double(counter.count)
        
        if counter.count < 0 {
            interval = duration/(Double(counter.count*(-1)))
        }
        
        _ = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { (timer) in
            if counter.count > 0 {
                if count <= counter.count {
                    countLabel.text = "\(count)"
                    count = count+1
                } else {
                    timer.invalidate()
                }
            } else {
                if count >= counter.count {
                    countLabel.text = "\(count)"
                    count = count-1
                } else {
                    timer.invalidate()
                }
            }
        })
    }
    
    func updateShortcutItems() { // Update 3D touch shortcuts with registered counters
        UIApplication.shared.shortcutItems = []
        for counter in Counter.counters {
            let newItem = UIMutableApplicationShortcutItem(type: "open", localizedTitle: counter.name)
            newItem.localizedSubtitle = "\(counter.count)"
            newItem.icon = UIApplicationShortcutIcon(type: .favorite)
            
            UIApplication.shared.shortcutItems?.append(newItem)
        }
    }
    
    // -------------------------------------------------------------------------
    // MARK: UIApplicationDelegate
    // -------------------------------------------------------------------------

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        FirebaseApp.configure()
        
        if !FileManager.default.fileExists(atPath: Counter.sharedDir.path) {
            do {
                try FileManager.default.createDirectory(at: Counter.sharedDir, withIntermediateDirectories: true, attributes: nil)
            } catch let error {
                print("ERROR CREATING SHARED DIR: \(error.localizedDescription)")
            }
        }
        
        do {
            if try FileManager.default.contentsOfDirectory(atPath: Counter.sharedDir.path) == [] {
                FileManager.default.createFile(atPath: Counter.sharedDir.appendingPathComponent("Counter").path, contents: "0\n3".data(using: .utf8), attributes: nil)
            }
        } catch _ {}
        
        print(try! FileManager.default.contentsOfDirectory(atPath: Counter.sharedDir.path))
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = CountViewController.shared
        window?.makeKeyAndVisible()
        
        UNUserNotificationCenter.current().requestAuthorization(options: .badge) { (granted, error) in
            if let error = error {
                let errorAlert = UIAlertController(title: "Error!", message: error.localizedDescription, preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.window?.rootViewController?.present(errorAlert, animated: true, completion: nil)
            }
        }
                
        return true
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) { // 3D Touch shortcuts
        if shortcutItem.type == "open" { // Open selected counter
            let counterTitle = shortcutItem.localizedTitle
            
            do {
                let counter = try Counter(file: Counter.sharedDir.appendingPathComponent(counterTitle))
                self.currentCounter = counter.row
                
                UIApplication.shared.keyWindow?.rootViewController = CountViewController()
            } catch _ {}
        } else if shortcutItem.type == "createNew" { // Create new counter
            let newCounter = Counter(name: "Counter \(Counter.counters.count+1)", count: 0, color: Color(from: 3))
            Counter.create(counter: newCounter)
            
            self.currentCounter = newCounter.row
            
            UIApplication.shared.keyWindow?.rootViewController = CountViewController()
        }
    }
    
}

