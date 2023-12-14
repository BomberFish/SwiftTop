// bomberfish
// SwiftTopApp.swift – SwiftTop
// created on 2023-12-14

import SwiftUI

@main
struct SwiftTopApp: App {
    init() {
        // register some defaults
        if UserDefaults.standard.value(forKey: "timeInterval") == nil {
            UserDefaults.standard.setValue(1.0, forKey: "timeInterval")
        }
        
        if UserDefaults.standard.value(forKey: "autoRefresh") == nil {
            UserDefaults.standard.setValue(true, forKey: "autoRefresh")
        }
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
