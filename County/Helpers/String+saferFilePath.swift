//
//  String+sanitizedFileName.swift
//  County
//
//  Created by Adrian on 24.12.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import Foundation

extension String {
    var saferFilePath: String {
        let characterSet = CharacterSet(charactersIn: "\"\\/?<>:*|")
        return components(separatedBy: characterSet).joined(separator: "-")
    }
}
