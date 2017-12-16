//
//  InterfaceController.swift
//  watch Extension
//
//  Created by Adrian on 10.12.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class InterfaceController: WKInterfaceController, WCSessionDelegate {
    
    static var shared = InterfaceController()
    
    @IBOutlet var countLabel: WKInterfaceLabel!
    var counter = Counter.shared
    
    // -------------------------------------------------------------------------
    // MARK: Watch Conectivity
    // -------------------------------------------------------------------------
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("Error activating session: \(error.localizedDescription)")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) { // Process received message
        applyReceived(data: message)
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) { // Process received context
        applyReceived(data: applicationContext)
    }
    
    func applyReceived(data: [String:Any]) { // Process received data from phone
        
        // Parse data
        guard let name = data["name"] as? String else { return }
        guard let count = data["count"] as? Int else { return }
        guard let color = data["color"] as? Int else { return }
        
        print(data)
        
        // Create counter
        let counter = Counter(name: name, count: count, color: Color(from: color))
        Counter.shared = counter
        
        // Open counter
        WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: "Interface", context: "" as AnyObject)])
    }
    
    func sendToPhone() { // Send data to phone
        DispatchQueue.global(qos: .background).async {
            if WCSession.isSupported() {
                print("Send counter")
                WCSession.default.sendMessage(["name":self.counter.name,"count":self.counter.count,"color":Identifier(forColor: self.counter.color)], replyHandler: nil, errorHandler: nil)
            } else {
                print("Cannot send counter")
            }
        }
    }
    
    // -------------------------------------------------------------------------
    // MARK: WKInterfaceController
    // -------------------------------------------------------------------------
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        
        WCSession.default.delegate = self
        WCSession.default.activate()
        
        setTitle(counter.name)
        
        if !FileManager.default.fileExists(atPath: Counter.sharedDir.path) {
            do {
                try FileManager.default.createDirectory(at: Counter.sharedDir, withIntermediateDirectories: true, attributes: nil)
            } catch let error {
                print("ERROR CREATING SHARED DIR: \(error.localizedDescription)")
            }
        }
        
        InterfaceController.shared = self
        countLabel.setText("\(counter.count)")
        
        if counter.color != #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) {
            countLabel.setTextColor(counter.color)
        } else {
            countLabel.setTextColor(.white)
        }
        
    }
    
    
    // -------------------------------------------------------------------------
    // MARK: Actions
    // -------------------------------------------------------------------------
    
    @IBAction func add(_ sender: Any) { // Add
        counter.count += 1
        sendToPhone()
    }
    
    @IBAction func substract(_ sender: Any) { // Substract
        counter.count -= 1
        sendToPhone()
    }
    

}
