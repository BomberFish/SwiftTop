// bomberfish
// battteryStatus+prettyName.swift – SwiftTop
// created on 2024-01-31

import Foundation

extension UIDevice.BatteryState {
    var prettyName: String {
        switch self.rawValue {
        case 1:
            return "Unplugged"
        case 2:
            return "Charging"
        case 3:
            return "Full"
        default:
            return "Unknown"
        }
    }
}
