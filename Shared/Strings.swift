//
//  Strings.swift
//  County
//
//  Created by Adrian on 20.12.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import Foundation

class Strings {
    private init() {}
    
    static let yes = NSLocalizedString("yes", comment: "")
    static let no = NSLocalizedString("no", comment: "")
    static let cancel = NSLocalizedString("cancel", comment: "")
    static let `in` = NSLocalizedString("in", comment: "")
    
    static let counter = NSLocalizedString("counter", comment: "Default counter title")
    static let addNew = NSLocalizedString("addNew", comment: "Add new counter tab title")
    static let addGroup = NSLocalizedString("addGroup", comment: "Add new group tab title")
    static let group = NSLocalizedString("group", comment: "Group of counters")
    
    static let sponsored = NSLocalizedString("sponsored", comment: "Title for maximized ad")
    
    static var noCounter = NSLocalizedString("createFirstCounter", comment: "Text shown when there is no counter")
    
    class ChangeTitleAlert {
        private init() {}
        
        static let title = NSLocalizedString("changeTitleAlert.title", comment: "Title for alert to change title")
        static func message(forCounter counter: String) -> String {
            return String(format: NSLocalizedString("changeTitleAlert.message", comment: "Message for alert to change title"), counter)
        }
        static let placeholder = NSLocalizedString("changeTitleAlert.placeholder", comment: "Placeholder for textfield in alert to change title")
    }
    
    class ResetAlert {
        private init() {}
        
        static let title = NSLocalizedString("resetAlert.title", comment: "Title for alert to reset counter")
        static let message = NSLocalizedString("resetAlert.message", comment: "Message for alert to reset counter")
    }
    
    class CannotRenameCounter {
        private init() {}
        
        static let title = NSLocalizedString("cannotRenameCounter.title", comment: "Title for error renaming counter")
        static func message(forCounter counter: String) -> String {
            return String(format: NSLocalizedString("cannotRenameCounter.message", comment: "Message for error renaming counter"), counter)
        }
    }
}
