// bomberfish
// UIApplication+firstWindow.swift – CO2AndU
// created on 2024-01-18

import UIKit

extension UIApplication {
    var firstWindow: UIWindow? {
        if #available(iOS 15.0, *) {
            return (connectedScenes.first as? UIWindowScene)?.windows.first(where: { $0.isKeyWindow })
        } else {
            return windows.first(where: { $0.isKeyWindow })
        }
    }
    
    var absoluteFirstWindow: UIWindow? {
        if #available(iOS 15.0, *) {
            return (connectedScenes.first as? UIWindowScene)?.windows.first
        } else {
            return windows.first
        }
    }
    
    var allWindows: [UIWindow] {
        if #available(iOS 15.0, *) {
            return (connectedScenes.first as! UIWindowScene).windows
        } else {
            return windows
        }
    }
}
