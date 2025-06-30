//
//  UIDeviceExtension.swift
//  readeck
//
//  Created by Ilyas Hallak on 29.06.25.
//

import UIKit

extension UIDevice {
    static var isPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static var isPhone: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }
}
