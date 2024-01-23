//
//  Haptic++.swift
//  PsychicPaper
//
//  Created by Hariz Shirazi on 2023-02-04.
//

import Foundation
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

#if !canImport(UIKit)
enum FeedbackStyleShim {
    case light,medium,heavy,soft,rigid
}

enum FeedbackTypeShim {
    case success,warning,error
}
#endif

/// Wrapper around UIKit haptics
class Haptic {
    static let shared = Haptic()
    private init() { }
#if canImport(UIKit)
    /// Play haptic feedback
    func play(_ feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: feedbackStyle).impactOccurred()
    }
    
    /// Provide haptic user feedback for an action
    func notify(_ feedbackType: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(feedbackType)
    }
    
    /// Play feedback for a selection
    func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
    #else
    func play(_ feedbackStyle: FeedbackStyleShim) {
        print("Haptics not supported on macOS")
    }
    
    func notify(_ feedbackType: FeedbackTypeShim) {
        print("Haptics not supported on macOS")
    }
    
    func selection() {
        print("Haptics not supported on macOS")
    }
    #endif
}
