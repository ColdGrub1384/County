//
//  BackgroundColor.swift
//  County
//
//  Created by Adrian on 10.12.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit

// Returns sendable and savable Int from UIColor
func Identifier(forColor color: UIColor) -> Int {
    
    switch color {
    case #colorLiteral(red: 0.5725490451, green: 0, blue: 0.2313725501, alpha: 1):
        return 0
    case #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1):
        return 1
    case #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1):
        return 2
    case #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1):
        return 3
    case #colorLiteral(red: 0.1764705926, green: 0.01176470611, blue: 0.5607843399, alpha: 1):
        return 4
    case #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1):
        return 5
    case #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1):
        return 6
    default:
        return -1
    }
}

// Returns color from Int
func Color(from number: Int) -> UIColor {
    
    switch number {
    case 0:
        return #colorLiteral(red: 0.5725490451, green: 0, blue: 0.2313725501, alpha: 1)
    case 1:
        return #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
    case 2:
        return #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
    case 3:
        return #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
    case 4:
        return #colorLiteral(red: 0.1764705926, green: 0.01176470611, blue: 0.5607843399, alpha: 1)
    case 5:
        return #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
    case 6:
        return #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    default:
        return .clear
    }
}
