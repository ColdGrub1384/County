//
//  Counter.swift
//  County
//
//  Created by Adrian on 08.12.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit

class Counter: NSObject {
    
    // -------------------------------------------------------------------------
    // MARK: Static declarations
    // -------------------------------------------------------------------------
    
    enum Action {
        case add
        case substract
    }
    
    static let sharedDir = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.countyCounter")!.appendingPathComponent("Counters")
    static let userDefaults = UserDefaults(suiteName: "group.countyCounter")!
    
    // iOS ONLY
    #if os(iOS)
    @discardableResult static func create(counter: Counter) -> Bool { // Register a new counter and save it to the disk
        return FileManager.default.createFile(atPath: sharedDir.appendingPathComponent(counter.name).path, contents: "\(counter.count)\n\(Identifier(forColor: counter.color))".data(using: .utf8), attributes: nil) // Create file called as the counter with count and color as content
    }
    
    static var counters: [Counter] { // Returns counters saved to the disk
        get {
            var counters_ = [Counter]()
            do {
                print(sharedDir.absoluteString)
                let files = try FileManager.default.contentsOfDirectory(at: sharedDir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) // Counter files
                // Parse files and add to array
                for file in files {
                    let content = try String(contentsOf: file, encoding: .utf8).components(separatedBy: "\n")
                    if content.count != 2 {
                        return counters_
                    }
                    guard let count = Int(content[0]) else { return counters_ }
                    guard let backColor = Int(content[1]) else { return counters_ }
                    counters_.append(Counter(name: file.lastPathComponent, count: count, color: Color(from: backColor)))
                }
            } catch _ {
                return counters_
            }
            
            return counters_
        }
        
        set { // Remove all counters and re add
            do {
                let files = try FileManager.default.contentsOfDirectory(at: sharedDir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                for file in files {
                    try FileManager.default.removeItem(at: file)
                }
                
                for counter in newValue {
                    FileManager.default.createFile(atPath: sharedDir.appendingPathComponent(counter.name).path, contents: "\(counter.count)\n\(Identifier(forColor: counter.color))".data(using: .utf8), attributes: nil)
                }
            } catch _ {
                return
            }
        }
    }
    
    // Watch OS ONLY
    #else
    static var shared: Counter { // Returns the only counter saved to the disk
        get {
            return Counter(name: Counter.userDefaults.string(forKey: "name") ?? "Counter", count: userDefaults.integer(forKey: "count"), color: Color(from: (userDefaults.value(forKey: "color") as? Int) ?? 3) )
        }
        
        set {
            userDefaults.set(newValue.count, forKey: "count")
            userDefaults.set(Identifier(forColor: newValue.color), forKey: "color")
            userDefaults.set(newValue.name, forKey: "name")
        }
    }
    
    static func create(counter: Counter) { // Replace shared counter
        shared = counter
    }
    #endif
    
    
    // -------------------------------------------------------------------------
    // MARK: Instance
    // -------------------------------------------------------------------------
    
    // Configure counter
    
    init(file: URL) throws {
        let content = try String(contentsOf: file, encoding: .utf8).components(separatedBy: "\n")
        if content.count != 2 {
            
        }
        
        let cannotReadData = StringError("Cannot read data from \(file.absoluteString).")
        
        guard let count = Int(content[0]) else { throw cannotReadData }
        guard let backColor = Int(content[1]) else { throw cannotReadData }
        
        self.name_ = file.lastPathComponent
        self.oldName = file.lastPathComponent
        self.count_ = count
        self.color_ = Color(from: backColor)
    }
    
    init(name: String, count: Int, color: UIColor) {
        self.name_ = name
        self.oldName = name
        self.count_ = count
        self.color_ = color
    }
    
    // For iOS, Background Color, and for Watch OS, Text Color
    private var color_: UIColor
    var color: UIColor {
        get {
            return color_
        }
        
        set {
            color_ = newValue
            sync()
        }
    }
    
    // Counter's name
    private var oldName: String
    private var name_: String
    var name: String {
        get {
            return name_
        }
        
        set {
            name_ = newValue
            sync()
        }
    }
    
    // Count
    private var count_: Int
    var count: Int {
        get {
            return count_
        }
        
        set {
            count_ = newValue
            
            #if os (iOS)
                UIApplication.shared.applicationIconBadgeNumber = newValue
                CountViewController.shared.countLabel.text = "\(newValue)"
                sync()
            #else
                InterfaceController.shared.countLabel.setText("\(newValue)")
            #endif
        }
    }
    
    // iOS ONLY
    #if os(iOS)
    
    // Row in counters array
    var row: Int {
        var i = 0
        for counter in Counter.counters {
            if counter.count_ == count_ && counter.name_ == name_ {
                return i
            }
            i = i+1
        }
        
        return i
    }
    
    // Remove counter from disk
    func remove() {
        
        var i = 0
        for counter in Counter.counters {
            if counter.count == count && counter.name == name {
                Counter.counters.remove(at: i)
                break
            }
            
            i = i+1
        }
    }
    #endif
    
    
    // Save changes
    @discardableResult func sync() -> Bool {
        
        let sharedFile = Counter.sharedDir.appendingPathComponent(name)
        let oldFile = Counter.sharedDir.appendingPathComponent(oldName)
        
        do {
            try FileManager.default.removeItem(at: oldFile) // Remove old file
        } catch _ {}
        
        oldName = name
            
        return FileManager.default.createFile(atPath: sharedFile.path, contents: "\(count)\n\(Identifier(forColor: color))".data(using: .utf8), attributes: nil) // Recreate the file with updated data and name
    }
}
