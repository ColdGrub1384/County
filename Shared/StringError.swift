//
//  StringError.swift
//  County
//
//  Created by Adrian on 17.12.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import Foundation

struct StringError : LocalizedError
{
    var errorDescription: String? { return mMsg }
    var failureReason: String? { return mMsg }
    var recoverySuggestion: String? { return "" }
    var helpAnchor: String? { return "" }
    
    private var mMsg : String
    
    init(_ description: String)
    {
        mMsg = description
    }
}
