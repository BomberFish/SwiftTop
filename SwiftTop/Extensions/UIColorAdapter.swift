// bomberfish
// UIColorAdapter.swift – SwiftTop
// created on 2023-12-15

import Foundation

#if !canImport(UIKit)
import AppKit

struct UIColor {
    static var label: NSColor = .labelColor
    static var systemBackground: NSColor = .windowBackgroundColor
    static var systemGroupedBackground: NSColor = .windowBackgroundColor
    static var secondarySystemGroupedBackground: NSColor = .underPageBackgroundColor
    static var systemGray: NSColor = .systemGray
    static var systemRed: NSColor = .systemRed
}
#endif
