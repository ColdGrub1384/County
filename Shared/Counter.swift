//
//  Counter.swift
//  County
//
//  Created by Adrian on 08.12.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit

class Counter {
    
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
    @discardableResult static func create(counter: Counter, inside dir: URL = sharedDir) -> Bool { // Register a new counter and save it to the disk
        return FileManager.default.createFile(atPath: dir.appendingPathComponent(counter.name).path, contents: "\(counter.count)\n\(Identifier(forColor: counter.color))".data(using: .utf8), attributes: nil) // Create file called as the counter with count and color as content
    }
    
    static func counters(atDirectory dir: URL) -> [Counter] {
        
        var parent: Counter?
        
        var counters_ = [Counter]()
        do {
            let files = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) // Counter files
            
            // Parse files and add to array
            for file in files {
                
                var isDir: ObjCBool = false
                
                if FileManager.default.fileExists(atPath: file.path, isDirectory: &isDir) {
                    if isDir.boolValue {
                        // Is folder
                        
                        var content = counters(atDirectory: file)
                        
                        var i = 0
                        for counter in content {
                            if counter.isGroup { // A parent cannot be his own parent
                                content.remove(at: i)
                            }
                            i += 1
                        }
    
                        var color = Color(from: 3)
                        if let firstCounter = content.first { color = firstCounter.color }
                        let counter = Counter(name: file.lastPathComponent, count: 0, color: color, childs: content)
                        counters_.append(counter)
                    } else {
                        // Is counter
                        
                        let content = try String(contentsOf: file, encoding: .utf8).components(separatedBy: "\n")
                        if content.count != 2 {
                            return counters_
                        }
                        guard let count = Int(content[0]) else { return counters_ }
                        guard let backColor = Int(content[1]) else { return counters_ }
    
                        let newCounter = Counter(name: file.lastPathComponent, count: count, color: Color(from: backColor))
                        counters_.append(newCounter)
                    }
                }
                
            }
    
        } catch _ {
            return counters_
        }
        
        if dir != sharedDir && counters_.count > 0 { // If is in a group, declare parent
            parent = Counter(name: dir.lastPathComponent, count: 0, color: counters_.last!.color, childs: counters_)
            for newCounter in counters_ {
                if !newCounter.isGroup {
                    newCounter.parent = parent
                }
            }
        }
        
        return counters_
    }
    
    static var counters: [Counter] { // Returns counters saved to the disk
        get {
            return counters(atDirectory: sharedDir)
        }
        
        set { // Remove all counters and re add
            do {
                let files = try FileManager.default.contentsOfDirectory(at: sharedDir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                for file in files {
                    
                    var isDir: ObjCBool = false
                    
                    if FileManager.default.fileExists(atPath: file.path, isDirectory: &isDir) {
                        if !isDir.boolValue {
                            try FileManager.default.removeItem(at: file)
                        }
                    }
                    
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
            return Counter(name: Counter.userDefaults.string(forKey: "name") ?? Strings.counter, count: userDefaults.integer(forKey: "count"), color: Color(from: (userDefaults.value(forKey: "color") as? Int) ?? 3) )
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
    
    #if os(iOS)
    init(file: URL) throws {
        
        self.name_ = String()
        self.oldName = String()
        self.count_ = Int()
        self.color_ = UIColor()
    
        let fileNotFound = StringError("File \(file.absoluteString) doesn't exit.")
    
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: file.path, isDirectory: &isDir) {
            if isDir.boolValue {
                // Is folder
                
                var content = Counter.counters(atDirectory: file)
                var count = 0
                var i = 0
                for counter_ in content {
                    count = count+counter_.count
                    counter_.parent = self
                    if counter_.isGroup {
                        content.remove(at: i)
                    }
                    i += 1
                }
                
                var color = Color(from: 0)
                if let firstCounter = content.first { color = firstCounter.color }
                self.name_ = file.lastPathComponent
                self.count_ = count
                self.color_ = color
                self.childs_ = content
                self.isGroup_ = true
            } else {
                // Is counter
                
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
        } else {
            throw fileNotFound
        }
    }
    #endif
    
    init(name: String, count: Int, color: UIColor) {
        self.name_ = name
        self.oldName = name
        self.count_ = count
        self.color_ = color
    }
    
    init(name: String, count: Int, color: UIColor, childs: [Counter]) {
        self.name_ = name
        self.oldName = name
        self.count_ = count
        self.color_ = color
        #if os(iOS)
        self.childs_ = childs
        self.isGroup_ = true
            
        // There is no child without parent 😊
        for child in childs {
            child.parent = self
        }
        #endif
    }
    
    #if os(iOS)
    var groupDirectory: URL? { // Group folder if it's
        if isGroup {
            return Counter.sharedDir.appendingPathComponent(name)
        } else {
            return nil
        }
    }
    
    var parent: Counter? // Parent group
    private var isGroup_ = false
    var isGroup: Bool {
        return isGroup_
    }

    // If is a folder, content of the folder
    private var childs_ = [Counter]()
    var childs: [Counter] {
        get {
            return childs_
        }
        
        set { // Remove all couters and re add
            guard let dir = groupDirectory else {
                return
            }
            
            do {
                let files = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                for file in files {
                    var isDir: ObjCBool = false
    
                    if FileManager.default.fileExists(atPath: file.path, isDirectory: &isDir) {
                        if !isDir.boolValue {
                            try FileManager.default.removeItem(at: file)
                        }
                    }
                }
                
                for counter in newValue {
                    FileManager.default.createFile(atPath: dir.appendingPathComponent(counter.name).path, contents: "\(counter.count)\n\(Identifier(forColor: counter.color))".data(using: .utf8), attributes: nil)
                }
            } catch _ {
                return
            }
        }
    }
    
    #endif
    
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
            
            #if os(iOS)
            if isGroup {
                // If is group, return count of all childs
                
                var count_ = 0
                for child in childs {
                    count_ = count_+child.count
                }
                
                return count_
            }
            #endif
            
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
        var array = Counter.counters
        if let parent = parent {
            array = parent.childs
        }
        for counter in array {
            if counter.count_ == count_ && counter.name_ == name_ {
                return i
            }
            i = i+1
        }
        
        return i
    }
    
    // Remove counter from disk
    func remove() {
    
        if isGroup {
            guard let dir = groupDirectory else { return }
            try? FileManager.default.removeItem(at: dir)
        }
    
        var i = 0
    
        if let parent = parent {
            for counter in parent.childs {
                if counter.count == count && counter.name == name {
                    parent.childs.remove(at: i)
                    break
                }
    
                i = i+1
            }
    
            return
        }
    
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
        
        var dir = Counter.sharedDir
        
        #if os(iOS)
            if isGroup {
                // Don't do anything if is a group
                return false
            }
            
            if let parent = parent {
                if let dir_ = parent.groupDirectory {
                    dir = dir_
                }
            }
        #endif
        
        
        let sharedFile = dir.appendingPathComponent(name)
        let oldFile = dir.appendingPathComponent(oldName)
        
        do {
            try FileManager.default.removeItem(at: oldFile) // Remove old file
        } catch _ {}
        
        oldName = name
            
        return FileManager.default.createFile(atPath: sharedFile.path, contents: "\(count)\n\(Identifier(forColor: color))".data(using: .utf8), attributes: nil) // Recreate the file with updated data and name
    }
}
