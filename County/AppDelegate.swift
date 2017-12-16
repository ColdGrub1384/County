 //
//  AppDelegate.swift
//  County
//
//  Created by Adrian on 08.12.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit
import UserNotifications

@UIApplicationMain
 class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    static let shared = AppDelegate()
    
    var currentCounter: Int {
        get {
            let returnValue = Counter.userDefaults.integer(forKey: "currentCounter")
            return returnValue
        }
        
        set {
            Counter.userDefaults.set(newValue, forKey: "currentCounter")
        }
    }
    
    func switchToCounter(_ counter: Counter) {
        currentCounter = counter.row
        
        let counterVC = CountViewController()
        
        UIApplication.shared.keyWindow?.rootViewController = counterVC
        UIApplication.shared.applicationIconBadgeNumber = counter.count
        
        counterVC.sendToWatch()
    }
    
    func animation(forLabel countLabel: UILabel, withCounter counter: Counter, andDuration duration: Double) {
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
    
    // -------------------------------------------------------------------------
    // MARK: UIApplicationDelegate
    // -------------------------------------------------------------------------

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
                
        if !FileManager.default.fileExists(atPath: Counter.sharedDir.path) {
            do {
                try FileManager.default.createDirectory(at: Counter.sharedDir, withIntermediateDirectories: true, attributes: nil)
            } catch let error {
                print("ERROR CREATING SHARED DIR: \(error.localizedDescription)")
            }
        }
        
        do {
            if try FileManager.default.contentsOfDirectory(atPath: Counter.sharedDir.path) == [] {
                FileManager.default.createFile(atPath: Counter.sharedDir.appendingPathComponent("Counter 1").path, contents: "0\n3".data(using: .utf8), attributes: nil)
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
}

