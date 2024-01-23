// bomberfish
// UIUserInterfaceIdiom+isLargeScreenFormat.swift – CO2AndU
// created on 2024-01-15

import UIKit

extension UIDevice {
    /// Whether the current device is a large screen (iPad, Mac (When optimize interface for Mac is on), Apple TV, or Apple Vision Pro)
    var isLargeScreenFormat: Bool {
        let idiom = UIDevice.current.userInterfaceIdiom
        if #available(iOS 17.0, *) {
            // Vision Pro idiom is only present on iOS 17.0+
            return (idiom == .pad || idiom == .mac || idiom == .tv || idiom == .vision)
        } else {
            return (idiom == .pad || idiom == .mac || idiom == .tv)
        }
    }
    /// Whether the current device is a spatial computing device.
    var isXR: Bool {
        let idiom = UIDevice.current.userInterfaceIdiom
        if #available(iOS 17.0, *) {
            // Vision Pro idiom is only present on iOS 17.0+
            return idiom == .vision
        } else {
            return false
        }
    }
}

extension UIUserInterfaceIdiom {
    /// Whether the current idiom is a large screen (iPad, Mac (When optimize interface for Mac is on), Apple TV, or Apple Vision Pro)
    var isLargeScreenFormat: Bool {
        if #available(iOS 17.0, *) {
            return (self == .pad || self == .mac || self == .tv || self == .vision)
        } else {
            return (self == .pad || self == .mac || self == .tv)
        }
    }
    /// Whether the current idiom is a spatial computing device.
    var isXR: Bool {
        if #available(iOS 17.0, *) {
            return self == .vision
        } else {
            return false
        }
    }
    
    /// Formatted name of the current idiom.
    var prettyName: String {
        switch self {
        case .pad:
            return "iPad"
        case .phone:
            return "iPhone"
        case .carPlay:
            return "CarPlay"
        case .mac:
            return "Mac Catalyst"
        case .tv:
            return "Apple TV"
        case .unspecified:
            return "Unspecified"
        case .vision:
            return "Apple Vision Pro"
        default:
            return "Unknown Idiom with raw value \(self.rawValue)"
        }
    }
}
